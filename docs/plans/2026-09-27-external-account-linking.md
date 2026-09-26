# 外部アカウント連携

方針は [ADR-0004](../adr/0004-external-account-linking.md) にある。

## 変更するファイル

### 設定とスキーマ

- `config/application.rb`、`config/initializers/required_env.rb`、`.env.example` — Active Record Encryptionの鍵を環境変数から設定
- `config/initializers/omniauth.rb` — Google連携で要求するscopeを役割に応じて設定
- `db/migrate/*_add_google_credentials_to_users.rb`、`db/schema.rb` — refresh tokenと取得済みscopeの列を追加
- `app/models/user.rb`、`app/models/person.rb` — 資格情報の暗号化、破棄、ロール変更と削除時の処理
- `app/services/google_token_revoker.rb` — Googleのトークン取り消し

### 認証と連携

- `config/routes.rb` — Google連携と解除の経路を追加し、ログインのコールバックをDiscordに限定
- `app/controllers/sessions_controller.rb` — Discordログインだけを処理
- `app/controllers/google_accounts_controller.rb` — 本人による連携と、本人または管理者による解除
- `app/controllers/manage/users_controller.rb` — Discordの`User`だけを紐づけ、削除時に資格情報を破棄
- `app/policies/google_account_policy.rb`、`app/policies/user_policy.rb` — 連携と解除の認可

### 画面と説明

- `app/views/people/show.html.erb` — Google連携の状態、連携、解除の操作を追加
- `app/views/registrations/new.html.erb` — Discordだけをログイン手段として案内
- `app/views/manage/users/*.html.erb` — Discordの`User`だけを扱う表示へ変更
- `CLAUDE.md`、`README.md` — 認証と外部アカウント連携の説明を更新

### spec

- `spec/models/user_spec.rb`、`spec/models/person_spec.rb` — 暗号化と資格情報を破棄する契機を確認
- `spec/services/google_token_revoker_spec.rb` — Googleへの取り消し要求をスタブして確認
- `spec/policies/authorization_matrix_spec.rb` — 連携と解除の可否を役割ごとに固定
- `spec/requests/google_accounts_spec.rb` — 連携、解除、scope、認可を確認
- `spec/requests/sessions_spec.rb`、`spec/requests/registrations_spec.rb`、`spec/requests/manage/users_spec.rb` — Discord限定のログインと紐づけを確認
- `spec/requests/deletions_spec.rb` — `User`と`Person`の削除時の取り消しを確認
- `spec/system/` — ログイン手段とプロフィール画面の操作を確認

## 作業順序

1. planをcommitする
2. 資格情報の列、暗号化設定、モデルのspecを先に追加し、実装する
3. Google連携と解除のpolicy、request specを先に追加し、経路、コントローラー、画面を実装する
4. Discordだけのログインと管理画面の紐づけをspecで固定し、実装を変更する
5. ロール変更、`User`の削除、`Person`の削除で資格情報を破棄するspecを追加し、実装する
6. 説明とsystem specを更新する
7. 全検証を実行する

## 検証手順

- 対象のspecを実装前に実行し、失敗を確認する
- GoogleへのHTTP要求はWebMockでスタブし、refresh tokenを送ることを確認する
- `bin/rails db:migrate`と`bin/rails db:test:prepare`でスキーマを更新する
- `bin/rspec`
- `bin/rails tailwindcss:build`の後、Chromeを用意して`bin/rspec spec/system/`
- `prek run --all-files`
- `bin/ci`

## 詰まりそうな箇所

- OmniAuthのGoogle request phaseで、ログイン中の`Person`の役割に応じたscopeと再同意を設定する必要がある
- OAuthコールバックはDiscordログインとGoogle連携でセッションの扱いが異なるため、経路を分離する必要がある
- 暗号鍵を追加すると、テスト、開発、assets precompile、本番の各環境で起動条件が変わる
- ロールの代入は関連を即座に更新するため、GMと管理者を両方失う時点で資格情報を破棄する必要がある
