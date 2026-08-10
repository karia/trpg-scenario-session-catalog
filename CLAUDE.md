# CLAUDE.md

## セットアップ

```
mise install
cp .env.example .env
docker compose up -d
bin/rails db:prepare
```

Ruby と Node は mise で固定している。`mise exec --` を通すか、mise の shims を PATH に置く。

## 日常的に使うコマンド

| 目的 | コマンド |
| --- | --- |
| テスト | `bin/rspec` |
| 静的解析 | `bin/rubocop` / `bundle exec erb_lint --lint-all` / `bin/brakeman` |
| pre-commit を一括実行 | `prek run --all-files` |
| 開発サーバ | `bin/dev` |

## この repo の約束

- public repo である。クラスタ側の資格情報とリソース識別子を持ち込まない
- 設定はすべて環境変数から読む。Rails credentials は使わない（`config/master.key` は存在しない）
- マイグレーションはリリース時の Job が実行する。コンテナの entrypoint では走らせない
- 認可は Pundit に寄せる。`ApplicationPolicy` は既定で拒否し、`Scope` は空集合を返す
- テストは RSpec。実装より先にテストを書く
- インフラ（PostgreSQL、MinIO、Ingress、Cloudflare Tunnel）は `yuno04-k3s` で管理する
- 権限は Person に付く。`User` は認証に要る情報だけを持つ。`pundit_user` は `current_person`
- 最初の管理者は `bin/rails admin:grant EMAIL=... NAME=...` で作る。管理画面からは作れない
- シナリオの実データは git に置かない。書式は `db/seeds/scenarios.example.yml`、投入は `bin/rails db:seed`（冪等）
- 投入先の実データは `SCENARIOS_SEED_FILE` で差し替えられる。既定は gitignore 済みの `db/seeds/scenarios.yml`

## ドキュメント

- [ADR](docs/adr/) — 設計判断
- [実装計画](docs/plans/) — フェーズごとの作業手順
