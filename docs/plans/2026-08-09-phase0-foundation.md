# Phase 0: 土台

**目的**: `rails new` から k3s 上で起動確認できるところまでを一本通し、Phase 1 と Phase 2 を並行して進められる状態を作る。

**依存**: なし。このフェーズだけは逐次で進める。

**設計**: [ADR-0001](../adr/0001-application-architecture.md)

## 作成するファイル

| ファイル | 役割 |
| --- | --- |
| `mise.toml` | Ruby 3.4、Node、prek、pinact のバージョン固定 |
| `Gemfile` | 依存の宣言 |
| Rails アプリの雛形一式 | `rails new --database=postgresql --css=tailwind --skip-test` の出力 |
| `config/database.yml` | 接続情報を環境変数から読む形に書き換える |
| `config/storage.yml` | MinIO を S3 互換サービスとして定義する |
| `compose.yaml` | 開発用の PostgreSQL と MinIO |
| `.env.example` | このアプリが必要とする環境変数の一覧 |
| `app/controllers/health_controller.rb` | ヘルスチェック |
| `app/policies/application_policy.rb` | Pundit の既定。すべて拒否から始める |
| `app/controllers/concerns/current_user_stub.rb` | `current_user` を nil で返す差し替え点 |
| `spec/rails_helper.rb` ほか | RSpec の設定 |
| `spec/requests/health_spec.rb` | 最初のテスト |
| `.rubocop.yml` | rubocop-rails-omakase を継承 |
| `.pre-commit-config.yaml` | RuboCop、erb_lint、Brakeman |
| `.github/workflows/ci.yml` | テストと静的解析 |
| `.github/workflows/build.yml` | GHCR へのイメージ push |
| `.github/dependabot.yml` | 依存の更新 |
| `Dockerfile` / `.dockerignore` | Rails 8 の生成物を調整 |
| `pull_request_template.md` | PR テンプレート |
| `CLAUDE.md` | 開発コマンドとリポジトリ固有の約束 |

`yuno04-k3s` 側にも作業がある。
このリポジトリの成果物ではないが、Phase 0 の完了条件に含む。

## 作業順序

1. mise で Ruby と Node を固定し、`rails new` を実行する。ここで 1 回目のコミット
2. RSpec、FactoryBot、Capybara を導入し、`bin/rspec` が 0 件で成功する状態にする
3. ヘルスチェックのリクエストスペックを書き、失敗を確認してから実装する
4. `compose.yaml` に PostgreSQL と MinIO を置く。`bin/rails db:prepare` と `bin/rspec` がローカルで通ることを確認する
5. `config/storage.yml` に MinIO を定義し、Active Storage の添付と取得をテストで確認する
6. Pundit を Gemfile に入れる。`ApplicationPolicy` はすべて拒否、`current_user` は nil を返す形で置き、Phase 2 が中身を差し替える
7. RuboCop、erb_lint、Brakeman を導入し、`prek install` で pre-commit フックを入れる
8. GitHub Actions の CI を追加する。PostgreSQL は service コンテナで用意する
9. Dockerfile でイメージをビルドし、ローカルのコンテナで `/up` が返ることを確認する
10. GHCR への push ワークフローを追加する
11. `pinact run` でワークフロー内の action を SHA に固定する
12. `yuno04-k3s` に CloudNativePG、MinIO、Deployment、Service、Ingress を用意する
13. デプロイし、公開ホスト名で `/up` が返ることを確認する

## 検証手順

- `bin/rspec` がすべて成功する
- `bin/rubocop` と `bin/brakeman` が警告なしで終わる
- `ApplicationPolicy` が既定で拒否を返すことをスペックで確認できる
- `docker build` したイメージを起動し、`curl localhost:3000/up` が 200 を返す
- CI が GitHub 上で成功する
- GHCR にイメージが push されている
- k3s 上の Pod が Ready になり、公開ホスト名で `/up` が 200 を返す
- MinIO に対して Active Storage の添付が保存され、取得できる

## 詰まりそうな箇所

**Rails の credentials と環境変数**。
Rails 8 の Dockerfile は `RAILS_MASTER_KEY` を前提にする。
ADR で設定を環境変数に寄せると決めているため、credentials に機密を入れず、Secret から環境変数として渡す形に統一する。
どちらに寄せるかを曖昧にしたまま進めると、後から本番だけ動かない形になる。

**CloudNativePG の Secret と `DATABASE_URL` の形が合わない**。
CloudNativePG が発行する Secret はホスト、ユーザー、パスワードが別のキーに分かれている。
Rails 側で個別の環境変数から接続を組み立てるか、起動時に `DATABASE_URL` を合成するかを決めておく。

**MinIO はパススタイルのアクセスを要する**。
Active Storage の S3 サービス設定で `force_path_style` を有効にしないと、バケット名がサブドメインとして解決されて失敗する。

**Solid Queue と Solid Cache のデータベース配置**。
Rails 8 の既定はアプリ本体とは別のデータベースを使う。
CloudNativePG のクラスタに複数データベースを持たせるか、同一データベースに同居させるかを Phase 0 で決めておく。
後から変えるとマイグレーションの管理単位が動く。

**CI での Active Storage**。
CI に MinIO を立てるとジョブが重くなる。
テスト環境はローカルディスク、開発と本番は MinIO とし、サービス名だけを環境ごとに切り替える形が軽い。

**Pundit をこのフェーズで入れる理由**。
Phase 1 と Phase 2 の両方が Pundit に触る。
どちらか一方に導入を寄せると、並行して進めた側が相手の完了を待つことになる。
土台としてここで入れ、中身は Phase 2 が差し替える。

**MinIO の公開範囲**。
ジャケット画像は公開エリアからも参照される。
バケットを公開にするか、署名付き URL で配信するかで、キャッシュのされ方と SEO 上の扱いが変わる。
`yuno04-k3s` 側の設計と合わせて決める。
