# ADR-0003: 外部アカウント連携の役割分担

- 日付: 2026-08-25
- ステータス: 提案中
- 対象: 認証、`User` と `Person` の紐づけ、YouTube Data API のトークン

## 背景

Google と Discord はどちらもログイン手段であり、`SessionsController#create` が同じ経路で受ける。
どちらでログインしたかで別の `User` ができるため、同一人物の `Person` が分かれうる。
実際に本番で分かれている。

[Issue #149](https://github.com/karia/trpg-scenario-session-catalog/issues/149) は、セッション情報から YouTube のライブ配信枠を作り、GM の録画一覧からセッション情報を生成することを目指す。
どちらも GM 本人のチャンネルへの API 呼び出しであり、本人が画面を開いていない時刻にも使うため refresh token を保持する必要がある。
`users` にトークンを置く列は無い。

## 決定

### Google と Discord の役割を分ける

Discord を唯一のログイン手段とし、Google は**ログイン済みの利用者が自分の `Person` に足す連携**とする。
管理者も例外としない。

- Google では新規登録もログインもできない。callback は連携としてのみ受け付け、未ログインなら失敗させる
- Google の連携と解除は本人が行う。管理者は他人の連携を解除できるが、紐づけはできない

### `Person` への紐づけ経路は残す

Issue #149 は「アカウントの紐づけ」画面を廃止するとしていたが、これは採らない。
廃止するのは Google の紐づけだけとし、Discord の `User` を `Person` へ結ぶ経路は残す。

`sync_discord_groups!` が `Person` を作るのは登録済みギルドへの所属を確認できたときだけで、所属していない利用者は `person_id` が nil のまま入る。
`pundit_user` は `current_person` なので、この利用者は自力で抜けられない。
また管理者が先に作った `Person` を持つ人が初めて Discord でログインすると、別の `Person` が新たに作られる。

紐づけを事前に行えるようにする案は [Issue #152](https://github.com/karia/trpg-scenario-session-catalog/issues/152) で別に扱う。

### YouTube の scope は `youtube.force-ssl` だけを要求する

`force-ssl` は読み取りを含むため、`youtube.readonly` を併せて要求しても同意画面が広がるだけで得るものが無い。

要求するのは連携時に GM または管理者である場合に限る。
権限は後から付与されるため、連携後に GM になる利用者がいる。
遡って再認証を求めず、**YouTube の機能を実際に使う時点で再連携を促す**。

### トークンは暗号化して `users` に持つ

refresh token と access token、有効期限、取得済み scope を `users` に持たせ、Active Record Encryption で暗号化する。
暗号鍵は環境変数から読み、起動時に欠落を検出する。
この repo は Rails credentials を使わず `config/master.key` を持たないためである。

連携の解除では、保存したトークンを破棄し Google 側でも revoke する。
`Person` は `has_many :users, dependent: :nullify` なので、`Person` を消しても `users` の行は残る。
`Person` の削除でもトークンを破棄する。

## 検討した代替案

### 連携用の別テーブルを作る

`user_credentials` へ分ければ provider が増えたときに素直だが、今回扱うのは Google だけで、`User` が既に provider ごとの行になっているため 1 対 1 が並ぶだけになる。
Discord にも保存すべきトークンが出た時点で分ける。

### Google をログイン手段のまま残す

変更は小さいが、どちらでログインしたかで `Person` が分かれる状態が続く。

### 鍵を Rails credentials に置く

Active Record Encryption の既定の置き場所だが、設定を環境変数から読む方針と衝突し、`config/master.key` をイメージへ入れることになる。

## 帰結

Discord が唯一のログイン経路になる。
障害中は管理者も含めて誰もログインできず、管理画面から復旧操作を行うこともできない。
退避路を設けないのは、それが「管理者だけ Google でも入れる」という条件付きの経路になり、条件の判定と維持に恒久的な制約を生むためである。

Discord が応答しても問い合わせが失敗した場合は、ログインは成功するのに所属が破棄され、見えていたセッションが見えなくなる。
以前からある挙動だが依存度が上がる以上そのままにはできない。
本 ADR の対象外とし、[Issue #151](https://github.com/karia/trpg-scenario-session-catalog/issues/151) で扱う。

暗号鍵を失うと保存済みのトークンは復号できない。
再連携を求めれば復旧できるが、鍵はデータベースのバックアップとは別に保管する必要がある。

本番には同一人物の `Person` が 2 件ある。
`id=1` が Google と `admin`、`id=5` が Discord と `gm` を持つ。
**唯一の管理者が Google 側にいるため、統合はこの変更の前提条件になる。**
統合しないまま移行すると、Discord でログインした側が管理者権限を持たず、管理画面へ入れる者がいなくなる。

利用者は現在 2 名でどちらも本人であるため、移行のための経過措置は設けない。
