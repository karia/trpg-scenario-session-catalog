# trpg-scenario-session-catalog

TRPG のシナリオとセッションのカタログサイト。

シナリオ情報は誰でも閲覧できる。
セッション情報は Google 認証でログインし、参加者と同じグループに所属しているユーザーだけが閲覧できる。

## ドキュメント

- [ADR](docs/adr/) — アプリケーションの設計判断
- [実装計画](docs/plans/) — フェーズごとの作業手順

インフラ（k3s、PostgreSQL、MinIO、公開経路）の構成は別リポジトリ `yuno04-k3s` で管理する。
