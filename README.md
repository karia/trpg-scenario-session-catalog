# trpg-scenario-session-catalog

TRPG のシナリオとセッションのカタログサイト。

シナリオ情報は誰でも閲覧できる。
セッション情報は Google 認証でログインし、参加者と同じグループに所属しているユーザーだけが閲覧できる。

公開先は <https://trpg-catalog.side2.net>。

## 動かす

必要なのは [mise](https://mise.jdx.dev/) と Docker の2つ。Ruby と Node は mise が入れる。

```bash
mise install
cp .env.example .env
docker compose up -d      # PostgreSQL と MinIO
bin/setup                 # 依存の取得、DB 作成、開発サーバの起動まで
```

`bin/setup` はサーバまで起動する。DB の用意だけしたいときは `bin/setup --skip-server`。

`.env` は編集しなくても動く。既定値が `compose.yaml` に合わせてある。
Google 認証を手元で試すときだけ `GOOGLE_CLIENT_ID` と `GOOGLE_CLIENT_SECRET` が要る。

シナリオが 0 件だと画面が寂しいので、見本を入れておくとよい。
`db/seeds/scenarios.example.yml` の 2 件が入る。何度流しても増えない。

```bash
bin/rails db:seed
```

## 変更を出す

```bash
bin/rspec                 # テスト
prek run --all-files      # RuboCop / erb_lint / Brakeman / gitleaks
```

この2つが通ることが、PR を出す前提。CI でも同じものが走る。

- ブランチを切って PR を出す。`main` へ直接 push しない
- commit はテーマごとに分ける。1 つの PR に複数テーマが混ざってもよいが、commit は混ぜない
- 実装より先にテストを書く。既存の実装を壊したときにテストが落ちることまで確かめる
- pre-commit の警告は skip しない。skip が要るときは PR にその理由を書く
- 画面や権限に触れる変更では、誰に何が見えるかを spec で固定する。この site は公開部分と非公開部分が同じプロセスに同居していて、認可の漏れがそのまま情報漏えいになる

設計上の判断とその理由は [ADR](docs/adr/) にある。
実装前にそこを読み、判断を変えるときは ADR を先に更新する。

## 構成

Rails 8 の SSR モノリス。画面は Hotwire、認可は Pundit、ファイルは Active Storage 経由で MinIO に置く。
詳しくは [ADR-0001](docs/adr/0001-application-architecture.md) を読む。

インフラ（k3s、PostgreSQL、MinIO、公開経路）は別リポジトリ `yuno04-k3s` で管理する。
このリポジトリが持つのは、アプリのコード、Dockerfile、CI、必要な環境変数の仕様まで。

## ドキュメント

| 場所 | 内容 |
| --- | --- |
| [docs/adr/](docs/adr/) | 設計判断と、採らなかった選択肢 |
| [docs/plans/](docs/plans/) | フェーズごとの作業手順 |
| [CLAUDE.md](CLAUDE.md) | 開発時の手順と、この repo の約束 |
