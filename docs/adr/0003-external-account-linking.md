# ADR-0003: 外部アカウント連携の役割分担

- 日付: 2026-08-25
- ステータス: 提案中
- 対象: 認証、`User` と `Person` の紐づけ、YouTube Data API のトークン

## 背景

Google と Discord はどちらもログイン手段であり、`SessionsController#create` が同じ経路で受ける。
どちらでログインしたかで別の `User` ができるため、同一人物の `Person` が分かれうる。
実際に本番でも分かれていたため、この決定の前提として `id=1` へ統合した。

[Issue #149](https://github.com/karia/trpg-scenario-session-catalog/issues/149) は、セッション情報から YouTube のライブ配信枠を作り、GM の録画一覧からセッション情報を生成することを目指す。
どちらも GM 本人のチャンネルへの API 呼び出しであり、本人が画面を開いていない時刻にも使うため refresh token を保持する必要がある。
`users` にトークンを置く列は無い。

## 決定

### Google と Discord の役割を分ける

Discord を唯一のログイン手段とし、Google は**ログイン済みの利用者が自分の `Person` に足す連携**とする。
管理者も例外としない。

- Google では新規登録もログインもできない
- Google の連携と解除は本人が行う。管理者は他人の連携を解除できるが、紐づけはできない

### `Person` への紐づけ経路は残す

Issue #149 は「アカウントの紐づけ」画面を廃止するとしていたが、これは採らない。
廃止するのは Google の紐づけだけとし、Discord の `User` を `Person` へ結ぶ経路は残す。
画面が扱えるのは Discord の `User` に限る。
Google の `User` はトークンを持つため、紐づけ先を付け替えられると他人のチャンネルへのトークンがその `Person` へ移る。

`sync_discord_groups!` が `Person` を作るのは登録済みギルドへの所属を確認できたときだけで、所属していない利用者は `person_id` が nil のまま入る。
`pundit_user` は `current_person` なので、この利用者は自力で抜けられない。

管理者が先に作った `Person` へ Discord のアカウントを事前に紐づける経路は、[Issue #152](https://github.com/karia/trpg-scenario-session-catalog/issues/152) で実装済みである。

### YouTube の scope は `youtube.force-ssl` だけを要求する

`force-ssl` は読み取りを含むため、`youtube.readonly` を併せて要求しても同意画面が広がるだけで得るものが無い。

要求するのは連携時に GM または管理者である場合に限る。
権限は後から付与されるため、連携後に GM になる利用者がいる。
遡って再認証を求めず、**YouTube の機能を実際に使う時点で再連携を促す**。

本人が画面の前にいない時刻に走る処理で scope が足りなかった場合は、黙って諦めず失敗として扱い、対象の GM へ通知する。
トークンを保持する目的が「画面を開いていない時刻にも使う」ことである以上、促す相手がいない経路が必ず存在する。

### トークンは暗号化して `users` に持つ

refresh token と取得済みの scope を `users` に持たせ、Active Record Encryption で暗号化する。
暗号鍵は環境変数から読む。
この repo は Rails credentials を使わず `config/master.key` を持たないためである。

連携の解除では、保存したトークンを破棄し Google 側でも revoke する。
管理者が `User` ごと削除する経路でも同じく revoke する。行を消すだけでは Google 側の許可が残る。
GM と管理者のロールを失った利用者のトークンも破棄する。連携時に持っていた権限が根拠だったためである。
`Person` は `has_many :users, dependent: :nullify` なので、`Person` を消しても `users` の行は残る。
`Person` の削除でもトークンを破棄する。

## 検討した代替案

### 連携用の別テーブルを作る

`user_credentials` へ分ければ provider が増えたときに素直だが、今回扱うのは Google だけで、`User` が既に provider ごとの行になっているため 1 対 1 が並ぶだけになる。
Discord にも保存すべきトークンが出た時点で分ける。

### Google をログイン手段のまま残す

変更は小さいが、どちらでログインしたかで `Person` が分かれる状態が続く。

### 鍵を Rails credentials に置く

Active Record Encryption の既定の置き場所である。
`RAILS_MASTER_KEY` で鍵を渡せるためイメージへ `config/master.key` を入れる必要はなく、環境変数から読む方針とも衝突しない。
それでも採らないのは、この repo が credentials そのものを使わないと決めており、暗号鍵のためだけに復活させると設定の在り処が 2 つに分かれるためである。

## 帰結

Discord が唯一のログイン経路になる。
障害中は管理者も含めて誰もログインできず、管理画面から復旧操作を行うこともできない。
退避路を設けないのは、それが「管理者だけ Google でも入れる」という条件付きの経路になり、条件の判定と維持に恒久的な制約を生むためである。

Discord への依存度が上がるため、問い合わせの失敗で所属グループが剥がれる挙動は [Issue #151](https://github.com/karia/trpg-scenario-session-catalog/issues/151) で先に直した。

暗号鍵を失うと保存済みのトークンは復号できない。
再連携を求めれば復旧できるが、鍵はデータベースのバックアップとは別に保管する必要がある。

ログインする利用者は本人 1 名であるため、移行のための経過措置は設けない。
