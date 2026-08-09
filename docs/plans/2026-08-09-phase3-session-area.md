# Phase 3: セッションエリア

**目的**: セッションの一覧と詳細を、参加者と同じグループの人にだけ見える形で提供する。シナリオ詳細にもセッション履歴を出す。

**依存**: Phase 1 と Phase 2 の両方。Phase 4 とは並行して進められる。

**設計**: [ADR-0001](../adr/0001-application-architecture.md)

## データモデル

- `PlaySession`: `scenario_id`、`played_at`（NULL 可）、`status`（予定 / 実施済み）、`recording_url`（NULL 可）
- `Participation`: `play_session_id`、`person_id`、`role`（GM / PL / サブキーパー）、`character_name`（NULL 可）、`character_sheet_url`（NULL 可）

キャラクターシートのリンクは参加者ごとに持つ。
GM とサブキーパーには存在しないことがあるため NULL を許す。

日時は未定を許す。
予定のセッションでは日付だけ決まっていて時刻が未定の場合があるため、日付と時刻を分けて持つか、日時を NULL 可にしたうえで補足を持たせるかを実装前に決める。

## 可視性

閲覧者の Person が次のいずれかを満たすとき、その `PlaySession` を閲覧できる。

- その `PlaySession` の参加者である
- その `PlaySession` の参加者の誰かと、同じグループに所属している

管理者はすべてを閲覧できる。

この判定は `PlaySessionPolicy::Scope` にだけ書く。
セッション一覧、セッション詳細、シナリオ詳細のセッション履歴は、すべてこの Scope を通す。

## 作成するファイル

- マイグレーション: `play_sessions`、`participations`
- モデル: `PlaySession`、`Participation`
- `app/policies/play_session_policy.rb`
- `app/controllers/play_sessions_controller.rb`
- `app/views/play_sessions/index.html.erb`、`show.html.erb`
- `app/views/scenarios/_play_session_history.html.erb`
- `app/avo/resources/play_session.rb`、`participation.rb`
- spec: モデルスペック、`spec/policies/play_session_policy_spec.rb`、`spec/requests/play_sessions_spec.rb`

## 作業順序

1. `PlaySession` と `Participation` のモデルスペックを書き、失敗を確認してから実装する
2. `PlaySessionPolicy::Scope` のスペックを先に書く。次の 6 通りを固定する
   - 未ログイン
   - ログイン済みだが Person 未紐づけ
   - Person に紐づいているが、参加者ともグループを共有していない
   - 参加者の誰かと同じグループに所属している
   - 参加者本人
   - 管理者
3. Scope を実装し、上のスペックを通す
4. セッション一覧のリクエストスペックを書いてから実装する
5. セッション詳細を同様に実装する。参加者ごとの役割、キャラクター名、キャラクターシートのリンクを出す
6. シナリオ詳細にセッション履歴を埋め込む。同じ Scope を通す
7. Avo に `PlaySession` と `Participation` のリソースを追加し、GM が登録できるようにする
8. 予定と実施済みの区別を一覧の表示に反映する

## 検証手順

- `bin/rspec` がすべて成功する
- 上の 6 通りそれぞれで、一覧に出る件数と詳細のステータスコードが期待どおりになる
- グループ外のユーザーが、URL を直接叩いてセッション詳細に到達できない
- シナリオ詳細のセッション履歴が、一覧と同じ絞り込みで表示される
- 参加者ごとのキャラクターシートのリンクが表示され、リンクのない参加者では欄が出ない
- 一覧の表示で N+1 クエリが出ない

## 詰まりそうな箇所

**Scope のクエリが重くなる**。
「参加者の所属グループ」を経由するため、素直に結合を重ねると行が膨らむ。
参加とグループ所属を経た EXISTS で書き、`SELECT DISTINCT` に頼らない形にする。

**判定の重複**。
詳細ページで Scope とは別に条件を書くと、片方だけ直したときに情報が漏れる。
`show` も Scope で引いた集合から探す形にし、条件式を 2 箇所に書かない。

**日時が未定のセッションの並び順**。
`played_at` が NULL の行を一覧のどこに置くかを決める。
NULL を末尾に固定しないと、データベースの既定の挙動に引きずられる。

**キャラクターシートのリンク先**。
外部サービスの URL を保存する。
セッションの可視性で保護されるのはリンクの表示だけであり、リンク先そのものは保護されない。
この前提を画面上でも分かるようにするか、リンクを持たせる運用にするかを決めておく。

**Person 未紐づけのユーザーの扱い**。
`current_person` が nil のとき、Scope は空集合を返す。
nil を渡した時点で例外になる実装にしないよう、スペックで先に固定する。
