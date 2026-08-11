# Issue #43 実装計画

## 目的

編集可能な各要素について、詳細画面と編集画面を相互に移動できるようにする。
作成・更新後の遷移先と一覧上の操作も詳細画面を中心に統一し、「もどる」の行き先を明示する。

対象 Issue: [#43 全ての要素に詳細画面を作成し、編集画面の相互遷移を可能にする](https://github.com/karia/trpg-scenario-session-catalog/issues/43)

## 方針

- 既存の公開詳細画面がある要素は、その画面を正規の詳細画面として再利用する。
- 公開詳細画面がない管理対象には、`manage` 配下に詳細画面を追加する。
- 一覧画面では各要素に「詳細」「編集」を併記する。
- 新規作成・更新に成功したら、対象要素の詳細画面へ遷移する。
- 編集画面のキャンセル導線は「詳細に戻る」に統一する。新規作成画面だけは対象がまだ存在しないため「一覧に戻る」とする。
- 削除後は対象の詳細画面が存在しなくなるため、従来どおり一覧へ遷移する。
- 認可は既存の Pundit policy に集約し、詳細表示の追加によって編集権限を広げない。

## 対象と遷移先

| 要素 | 一覧 | 詳細（正規 URL） | 編集 | 作成後 | 更新後 | 削除後 |
| --- | --- | --- | --- | --- | --- | --- |
| シナリオ | `manage_scenarios_path` | `scenario_path(record)` | `edit_manage_scenario_path(record)` | 詳細 | 詳細 | 管理一覧 |
| セッション | `manage_play_sessions_path` | `play_session_path(record)` | `edit_manage_play_session_path(record)` | 詳細 | 詳細 | 管理一覧 |
| 人物（管理編集） | `manage_people_path` | `person_path(record)` | `edit_manage_person_path(record)` | 詳細 | 詳細 | 管理一覧 |
| 人物（プロフィール編集） | `people_path` | `person_path(record)` | `edit_person_path(record)` | 対象外 | 詳細 | 対象外 |
| システム | `manage_game_systems_path` | `manage_game_system_path(record)` | `edit_manage_game_system_path(record)` | 詳細 | 詳細 | 管理一覧 |
| 作者 | `manage_authors_path` | `manage_author_path(record)` | `edit_manage_author_path(record)` | 詳細 | 詳細 | 管理一覧 |
| グループ | `manage_groups_path` | `manage_group_path(record)` | `edit_manage_group_path(record)` | 詳細 | 詳細 | 管理一覧 |
| Google アカウント | `manage_users_path` | `manage_user_path(record)` | `edit_manage_user_path(record)` | 対象外 | 詳細 | 対象外 |

Google アカウントも `person_id` を更新できる要素なので対象に含める。
一覧内のインライン編集を独立した編集画面へ移し、一覧・詳細・編集の役割を揃える。

## 認可と表示範囲

| 要素 | 詳細表示の認可 |
| --- | --- |
| シナリオ | 現行の `ScenarioPolicy#show?` を維持する |
| セッション | 現行の参加者・同一グループ・管理者に加え、GM を含む編集者が管理一覧に載る全セッションを詳細表示できるようにする |
| 人物 | 現行の `PersonPolicy#show?` を維持する |
| システム・作者 | 編集者のみ。各 policy に `show?` を追加する |
| グループ | 現行の `GroupPolicy#show?`（管理者のみ）を使用する |
| Google アカウント | 管理者のみ。`UserPolicy#show?` を追加する |

セッションの編集者は現状でも管理一覧と編集画面から全項目を閲覧できる。
この変更は編集権限を持つ利用者に限って、同じレコードを詳細形式でも表示可能にするものであり、一般メンバーの表示範囲は変えない。
公開セッション一覧は引き続き `PlaySessionPolicy::Scope` を使い、GM を含む編集者についても従来の表示範囲を維持する。

## 実装手順

1. ルーティングと controller action を整える。
   - `manage` 配下のシステム、作者、グループ、Google アカウントに `show` を追加する。
   - Google アカウントに `edit` を追加する。
   - `Manage::MastersController` の `show` / `edit` を独立画面として実装する。
   - 各 create/update の成功時 redirect を上表の詳細 URL に変更する。
2. 詳細画面を追加する。
   - システムと作者は名前と関連シナリオを表示する。
   - グループは名前と所属人物を表示する。
   - Google アカウントはメールアドレス、初回ログイン日時、紐づけ先人物を表示する。
   - 各画面に、権限に応じた「編集」リンクと一覧への導線を置く。
3. 既存の詳細・編集・一覧画面の導線を統一する。
   - 管理一覧の各行に「詳細」「編集」を併記する。
   - 編集フォームの「やめる」や一覧へ戻るリンクを「詳細に戻る」に変更する。
   - 公開側の詳細画面にある既存の編集リンクは維持する。
   - Google アカウントのインライン編集を編集画面へ移す。
4. Pundit policy と取得クエリを調整する。
   - 新設した詳細 action を既存の権限区分で認可する。
   - セッション詳細の取得だけを編集者向けに拡張し、公開一覧と共有する `PlaySessionPolicy::Scope` 自体は変更しない。
   - 詳細表示で使う関連データを eager load し、不要な N+1 query を避ける。
5. テストを追加・更新する。
   - 全対象について「一覧に詳細と編集がある」「詳細から編集できる」「編集から詳細へ戻れる」を request spec で固定する。
   - create/update 成功後が詳細への redirect になることを確認する。
   - 権限のない利用者には新設した管理詳細が 404 になることを確認する。
   - セッションは編集者が非参加セッションの詳細を表示でき、一般メンバーの可視範囲は広がらないことを確認する。
   - validation error 時は入力値とエラーを保持して編集画面を再表示することを確認する。
6. `CLAUDE.md` に今後の画面設計ルールを追記する。
   - 編集可能な要素には詳細画面を用意する。
   - 詳細と編集を相互リンクする。
   - 保存後は詳細へ、削除後は一覧へ遷移する。
   - 一覧には詳細と編集の両方を表示する。
7. `bin/rspec` と `prek run --all-files` を実行し、回帰がないことを確認する。

## 管理画面の統廃合（別 Issue）

管理画面の統合・廃止は工数が大きいため、別 Issue で扱う。
今回は既存の管理一覧を維持したまま、詳細画面と相互導線を追加する。

## 完了条件

- すべての更新可能要素に認可された詳細 URL がある。
- 詳細と編集を双方向に移動できる。
- 管理一覧から詳細と編集の両方へ移動できる。
- 作成・更新後に対象の詳細が表示される。
- ボタンやリンクから遷移先が読み取れる。
- 権限のない利用者の閲覧範囲が広がっていない。
- `CLAUDE.md` と request/policy spec に共通方針が固定されている。
