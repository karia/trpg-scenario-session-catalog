# ADR-0003: 外部アカウント連携の役割分担

- 日付: 2026-08-25
- ステータス: 提案中
- 対象: 認証、`User` と `Person` の紐づけ、YouTube Data API のトークン

## 背景

現在、Google と Discord はどちらもログイン手段である。
`SessionsController#create` はどちらの callback も同じ経路で受け、`User.from_omniauth` が `User` を作る。

`users` は `provider`、`uid`、`email`、`name` に加えて `person_id` と `google_uid` を持つ。
`google_uid` は provider 列を足す前の名残で、`from_omniauth` が既存行を見つけるためのフォールバックとして今も使う。

`Person` との紐づけには 2 つの経路がある。
管理者が `manage/users` で選ぶ経路と、Discord ログイン時に `sync_discord_groups!` が自動で作る経路である。
後者が `Person` を作るのは、`discord_guild_id` を持つ `Group` のいずれかに所属していると確認できたときに限る。

[Issue #149](https://github.com/karia/trpg-scenario-session-catalog/issues/149) は、セッション情報から YouTube のライブ配信枠を作り、GM の録画一覧からセッション情報を生成することを目指している。
どちらも GM 本人のチャンネルに対する API 呼び出しであり、本人の同意で得たトークンが要る。
GM が画面を開いていない時刻にも使うため、refresh token を保持する必要がある。
`users` にトークンを置く列は無い。

## 決定

### Google と Discord の役割を分ける

Discord をログイン手段とし、Google は**ログイン済みの利用者が自分の `Person` に足す連携**とする。

- 新規の利用者は Discord でログインする。Google での新規登録は受け付けない
- Google の連携と解除は、本人が `Person` の画面から行う
- 管理者は他人の Google 連携を**解除**できる。紐づけはできない

### `Person` への紐づけ経路は残す

Issue #149 は `manage/users` の「アカウントの紐づけ」を画面ごと廃止するとしていた。
これは採らない。
廃止するのは **Google の紐づけだけ**とし、Discord の `User` を既存の `Person` へ結ぶ操作は管理者に残す。

理由は 2 つある。
1 つは、`sync_discord_groups!` が `Person` を作るのは登録済みギルドへの所属を確認できたときだけであり、所属していない利用者は `person_id` が nil のまま入ることである。
`pundit_user` は `current_person` なので、この利用者は公開エリアしか見られない状態から自力で抜けられない。

もう 1 つは、管理者が先に作った `Person` を持つ人が初めて Discord でログインすると、`self.person ||= Person.create!` が別の `Person` を新たに作ることである。
これは本 ADR が解消しようとしている分裂そのものを再生産する。

### 退避路としての Google ログインを定義する

管理者は Google でもログインできる状態を残す。
Discord 側の障害でログインが塞がったとき、管理画面へ入る経路が完全に無くなるのを避けるためである。

ただし「管理者かどうか」は callback の時点では `User` が既にあって初めて分かる。
そこで受け付ける条件を次のとおり狭める。

**Google の callback は、その `uid` の `User` が既に存在し、かつ `admin` を持つ `Person` に紐づいているときだけログインとして扱う。**
それ以外は連携の操作としてのみ受け付け、未ログインなら失敗させる。

新しい Google アカウントからは退避路を作れない。
`bin/rails admin:grant` は既存の `User` 行を探すだけで作らないため、これは運用上の前提として受け入れる。
退避路を保つには、管理者の Google 連携を最後の 1 件まで解除させない制約が要る。

### YouTube の scope は `youtube.force-ssl` だけを要求する

Google の連携時、その `Person` が GM または管理者であれば YouTube Data API の scope を含めて要求する。

要求するのは `youtube.force-ssl` のみとする。
このスコープは読み取りを含むため、`youtube.readonly` を併せて要求しても同意画面が広がるだけで得るものが無い。

権限は後から付与されるため、連携時に権限を持たなかった利用者が後で GM になる場合がある。
このとき遡って再認証を求めず、**YouTube の機能を実際に使う時点で再連携を促す**。

scope は利用者ごとに変わるため、`config/initializers/omniauth.rb` の静的な指定では表せない。
request phase で差し替える。
同じ理由で `access_type` と `prompt` も連携のリクエストにだけ渡す。
provider の設定に書くと、管理者の通常ログインでも毎回同意画面が出る。

Google の callback はログインと連携の両方が通るため、**どちらの意図で始めたかを state に載せて区別する**。

### トークンは Active Record Encryption で暗号化して保持する

`users` に refresh token、access token、有効期限、取得済み scope を持たせ、Active Record Encryption で暗号化する。

鍵は `primary_key`、`deterministic_key`、`key_derivation_salt` の 3 つが要る。
この repo は Rails credentials を使わず `config/master.key` も持たないため、3 つとも環境変数から読み、`config/initializers/required_env.rb` の必須変数に加える。
1 つでも欠けると、起動は通るのに暗号化した属性へ初めて触れた時点で例外になる。

連携の解除では、保存したトークンを破棄し、Google 側でも revoke する。
`Person` は `has_many :users, dependent: :nullify` なので、`Person` を消しても `users` の行は残る。
`Person` の削除でもトークンを破棄する。

## 検討した代替案

### 連携用の別テーブルを作る

`user_credentials` のようなテーブルへ分ける案。
provider が増えたときに素直で、`users` を認証情報だけの薄いモデルに保てる。
ただし今回扱うのは Google だけであり、`User` が既に provider ごとの行になっているため、行が 1 対 1 で並ぶだけになる。
Discord にも保存すべきトークンが出てきた時点で分ける。

### Google をログイン手段のまま残す

変更が小さい。
しかし Google と Discord のどちらでログインしたかで `Person` が分かれる現在の状態が続く。
実際に本番では同一人物の `Person` が 2 件に分かれている。

### 鍵を Rails credentials に置く

Active Record Encryption の既定の置き場所であり、設定量が最も少ない。
しかし [The Twelve-Factor App](https://12factor.net/) に従って設定を環境変数から読む方針と衝突し、`config/master.key` をイメージへ入れる必要が生じる。
採らない。

## 帰結

Discord が主なログイン経路になるため、Discord 側の不調がそのまま利用者に届くようになる。

問い合わせが失敗すると、ログインは成功するのに `discord_managed` な所属が破棄される。
`PlaySessionPolicy::Scope` が可視性を所属で決めるため、見えていたセッションが見えなくなる。
以前からある挙動だが、依存度が上がる以上そのままにはできない。
本 ADR の対象外とし、[Issue #151](https://github.com/karia/trpg-scenario-session-catalog/issues/151) で扱う。

暗号鍵を失うと保存済みのトークンは復号できない。
利用者に再連携を求めれば復旧できるが、鍵はデータベースのバックアップとは別に保管する必要がある。

本番には同一人物の `Person` が 2 件ある。
`id=1` が Google と `admin`、`id=5` が Discord と `gm` を持つ。
この決定の下では 1 つの `Person` に両方の provider が紐づくため、2 件は統合する。
統合しないまま移行すると、Discord でログインした側が管理者権限を持たず、Google の連携も既に他の `Person` が使っているとして拒否される。

利用者は現在 2 名でどちらも本人であるため、移行のための経過措置は設けない。
