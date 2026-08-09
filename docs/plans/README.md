# 実装計画

設計は [ADR-0001](../adr/0001-application-architecture.md) にある。

## フェーズと依存

| フェーズ | 内容 | 依存 |
| --- | --- | --- |
| [Phase 0](2026-08-09-phase0-foundation.md) | 土台。Rails の雛形から k3s での起動確認まで | なし |
| [Phase 1](2026-08-09-phase1-scenario-public-area.md) | シナリオ公開エリアと管理画面での登録 | Phase 0 |
| [Phase 2](2026-08-09-phase2-authentication.md) | 認証、権限、グループ | Phase 0 |
| [Phase 3](2026-08-09-phase3-session-area.md) | セッションエリアと可視性 | Phase 1、Phase 2 |
| [Phase 4](2026-08-09-phase4-profile-and-favorites.md) | プロフィール、別名、お気に入り、ネタバレ防止ボタン | Phase 2 |

Phase 0 の完了後に Phase 1 と Phase 2 を並行して進められる。
その後 Phase 3 と Phase 4 を並行して進められる。

Phase 1 と Phase 2 には合流点が 2 つある。
広告と解析タグのログイン判定、そして Avo の有効化である。
どちらも Phase 1 が空実装を置き、Phase 2 が中身を差し替える。

## 今回の対象外

次の 3 つは要件に含まれるが、上のフェーズには入れていない。

- セッション登録時の Discord への通知。Phase 3 の完了後に Solid Queue のジョブとして追加する
- 本人による Google アカウントの差し替え。`User` の `google_uid` を更新するだけで足りるため、必要になった時点で追加する
- 元のスプレッドシートにある「今後行くかもしれないシナリオ」と「回してほしいと言われているシナリオ」の 2 表。カタログの一部ではなく個人のバックログであり、公開するかどうかも別の判断になる

## インフラ

PostgreSQL、MinIO、Ingress、Cloudflare Tunnel の構成は `yuno04-k3s` リポジトリで扱う。
Phase 0 の完了条件にはそちらの作業も含む。
