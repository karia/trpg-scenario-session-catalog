# ADR-0003: 外部アカウント連携の役割分担

- 日付: 2026-08-25
- ステータス: 提案中
- 対象: 認証、`User` と `Person` の紐づけ、YouTube Data API のトークン

## 背景

現在、Google と Discord はどちらもログイン手段である。
`SessionsController#create` はどちらの callback も同じ経路で受け、`User.from_omniauth` が `User` を作る。
`Person` との紐づけは管理者が `manage/users` で行う。

[Issue #149](https://github.com/karia/trpg-scenario-session-catalog/issues/149) は、セッション情報から YouTube のライブ配信枠を作り、GM の録画一覧からセッション情報を生成することを目指している。
どちらも GM 本人の YouTube チャンネルに対する API 呼び出しであり、本人の同意で得たトークンが要る。
ログインのたびに得られる短命のアクセストークンでは足りず、GM が画面を開いていない時刻にも使える refresh token を保持する必要がある。

`users` テーブルは今 `provider`、`uid`、`email`、`name` しか持たない。
トークンを置く場所が無い。

## 決定

### Google と Discord の役割を分ける

Discord をログイン手段とし、Google は**ログイン済みの利用者が自分の `Person` に足す連携**とする。

- 新規の利用者は Discord でログインする。Google での新規登録は受け付けない
- Google の連携と解除は、本人が `Person` の画面から行う
- 管理者は他人の Google 連携を**解除**できる。紐づけはできない
- `manage/users` の紐づけ編集は廃止する

管理者だけは Google でもログインできる状態を残す。
最初の管理者は `bin/rails admin:grant` で作るが、Discord サーバーの障害や Bot トークンの失効で Discord 経由のログインが塞がったとき、管理画面へ入る経路が完全に無くなるのを避けるためである。

### YouTube の scope は連携時に取得し、必要になった時点で追加する

Google の連携時、その `Person` が GM または管理者であれば YouTube Data API の scope を含めて要求する。
権限は後から付与されるため、連携時に権限を持たなかった利用者が後で GM になる場合がある。
このとき遡って再認証を求めず、**YouTube の機能を実際に使う時点で再連携を促す**。

要求する scope は `youtube.readonly` と `youtube.force-ssl` の両方とする。
後続タスクのうち録画一覧の読み取りは前者で足りるが、ライブ配信枠の作成は後者を要する。
2 度に分けて同意を求めるより、連携という 1 つの操作で完結させる。

### トークンは Active Record Encryption で暗号化して保持する

`users` に refresh token と access token、有効期限、取得済み scope を持たせ、Active Record Encryption で暗号化する。

暗号鍵は環境変数から渡す。
この repo は Rails credentials を使わない方針であり、`config/master.key` が存在しない。
鍵は `config/initializers/required_env.rb` の必須変数に加え、欠けたまま本番が起動しないようにする。

Google の OAuth は既定では refresh token を返さない。
`access_type: "offline"` と `prompt: "consent"` を指定する。

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
連携を「ログイン済みの本人が足す操作」に変えることで、この分岐が起きなくなる。

### 鍵を Rails credentials に置く

Active Record Encryption の既定の置き場所であり、設定量が最も少ない。
しかし [The Twelve-Factor App](https://12factor.net/) に従って設定を環境変数から読む方針と衝突し、`config/master.key` をイメージへ入れる必要が生じる。
採らない。

## 帰結

Discord が唯一のログイン経路になるため、Discord 側の障害はログインできない状態に直結する。
管理者だけ Google でも入れる状態を残すのは、この単一障害点に対する退避路である。

暗号鍵を失うと保存済みのトークンは復号できない。
利用者に再連携を求めれば復旧できるが、鍵はデータベースのバックアップとは別に保管する必要がある。

本番には同一人物の `Person` が 2 件ある。
`id=1` が Google と `admin`、`id=5` が Discord と `gm` を持つ。
この決定の下では 1 つの `Person` に両方の provider が紐づくため、2 件は統合する。
統合しないまま移行すると、Discord でログインした側が管理者権限を持たず、Google の連携も既に他の `Person` が使っているとして拒否される。

利用者は現在 2 名でどちらも本人であるため、移行のための経過措置は設けない。
