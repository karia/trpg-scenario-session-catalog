# UI 刷新

方針は [ADR-0002](../adr/0002-user-interface-design.md) にある。
各行を 1 タスク、1 PR として実施する。

## タスクと依存

| 順序 | 対象 | 依存 | 完了条件 |
| --- | --- | --- | --- |
| 1 | デザイントークンと基盤 | なし | 新トークン、`color-scheme: dark`、button と field と input を後続 PR から使える |
| 2 | アプリケーション枠 | 1 | 全画面の外枠、ナビゲーション、通知、エラー画面が新デザインになる |
| 3 | シナリオ一覧と並び順管理 | 1、2 | 一覧が画面幅で再配置され、絞り込みに横スクロールがない |
| 4 | シナリオ詳細 | 1、2 | ジャケット、基本情報、本文、限定情報が新デザインになる |
| 5 | シナリオの登録と編集 | 1、2 | フォーム項目、エラー、保存操作が共通部品へ移る |
| 6 | セッション一覧と詳細 | 1、2、4 | 日程、参加者、録画情報が画面幅で再配置される |
| 7 | セッションの登録と編集 | 1、2 | 日程と参加者の繰り返し入力が狭い画面でも 1 列で操作できる |
| 8 | 人物と利用登録 | 1、2 | 一覧、詳細、登録、編集がモバイルでも操作できる |
| 9 | マスター管理 | 1、2、8 | 作者、ゲームシステム、グループの管理画面が新デザインになる |
| 10 | ユーザーとサイト設定 | 1、2、8 | 管理画面の一覧、詳細、編集が新デザインになる |
| 11 | 横断監査と旧資産の削除 | 3〜10 | 旧トークン、旧共有部品、未使用テンプレートが残っていない |

共通部品を 3 つ、作る側と使う側でタスクをまたいで共有する。
`_video_link` はタスク 4 が作ってタスク 6 が使い、`_alias_fields` と `_self_demotion_warning` はタスク 8 が作ってタスク 9 とタスク 10 が使う。
これ以外のタスクは互いに独立しており、並行して進められる。

## 変更するファイル

### 1. デザイントークンと基盤

- `app/assets/tailwind/application.css` — `@theme` へ新トークンを追加、`color-scheme` を `dark` へ、base layer のフォーカス表示を更新
- `app/views/shared/ui/` — `_button`、`_field`、`_input` を新設
- `app/helpers/ui_helper.rb` — 部品のヘルパーを新設
- `Gemfile`、`spec/support/` — axe による自動チェックを追加

既存の `@theme` の 6 色は触らない。

### 2. アプリケーション枠

- `app/views/layouts/application.html.erb`、`manage.html.erb`、`error.html.erb`
- `app/views/manage/_nav.html.erb`
- `app/views/errors/show.html.erb`
- `app/views/shared/_ads.html.erb` — 広告枠の余白と境界
- `app/views/shared/ui/` — `_alert`、`_page_header`、`_navigation` を追加

### 3. シナリオ一覧と並び順管理

- `app/views/scenarios/index.html.erb`、`_table.html.erb`、`_gallery.html.erb`
- `app/views/scenario_order/index.html.erb`、`_scenarios.html.erb`
- `app/views/shared/ui/` — `_card`、`_badge`、`_empty_state`、`_filter_panel`、`_scenario_card` を追加

### 4. シナリオ詳細

- `app/views/scenarios/show.html.erb`、`_favorite_button.html.erb`、`_gm_supplementary_info.html.erb`、`_play_session_history.html.erb`、`_preparation_note.html.erb`
- `app/views/shared/ui/` — `_definition_list`、`_disclosure`、`_video_link` を追加

### 5. シナリオの登録と編集

- `app/views/scenarios/new.html.erb`、`edit.html.erb`
- `app/views/manage/scenarios/edit.html.erb`、`_form.html.erb`、`_link_fields.html.erb`、`_link_row.html.erb`

`scenarios/edit.html.erb` は `manage/scenarios/edit` を描画するだけで、見出しと画像操作のボタンは後者にある。
- `app/views/shared/ui/` — `_textarea`、`_select`、`_checkbox`、`_radio`、`_error_summary`、`_repeatable_fields` を追加

### 6. セッション一覧と詳細

- `app/views/play_sessions/index.html.erb`、`show.html.erb`
- `app/views/shared/ui/_play_session_card` を追加

### 7. セッションの登録と編集

- `app/views/play_sessions/new.html.erb`、`edit.html.erb`
- `app/views/manage/play_sessions/_form.html.erb`、`_participation_row.html.erb`、`_recording_link_row.html.erb`、`_session_schedule_row.html.erb`

### 8. 人物と利用登録

- `app/views/people/index.html.erb`、`show.html.erb`、`new.html.erb`、`edit.html.erb`、`_administration_fields.html.erb`
- `app/views/manage/people/_form.html.erb`
- `app/views/registrations/new.html.erb`
- `app/views/shared/ui/_person_card`、`_alias_fields`、`_self_demotion_warning` を追加

### 9. マスター管理

- `app/views/manage/masters/_index.html.erb`、`show.html.erb`、`new.html.erb`、`edit.html.erb`
- `app/views/manage/authors/index.html.erb`、`manage/game_systems/index.html.erb`
- `app/views/manage/groups/index.html.erb`、`show.html.erb`、`edit.html.erb`

継承元が 2 つある。
`AuthorsController` と `GameSystemsController` は top-level の `MastersController` を継承し、`manage/masters/*` を明示的に描画する。
`Manage::GroupsController` は別クラスの `Manage::MastersController` を継承し、こちらは明示的な描画を持たないため `manage/groups/*` が暗黙に描画される。
どちらも作者、ゲームシステム、グループの管理画面として同じ操作を提供するので 1 タスクにまとめるが、テンプレートは共有していない。

`manage/masters/edit.html.erb` は `shared/_alias_fields` を使う。タスク 8 で追加した部品へ差し替える。

### 10. ユーザーとサイト設定

- `app/views/manage/users/index.html.erb`、`show.html.erb`、`edit.html.erb`
- `app/views/manage/site_settings/show.html.erb`、`edit.html.erb`

`manage/users/edit.html.erb` は `shared/_self_demotion_warning` を使う。タスク 8 で追加した部品へ差し替える。

### 11. 横断監査と旧資産の削除

削除するもの。

- `app/assets/tailwind/application.css` の旧トークン (`ink`、`paper`、`surface`、`seal`、`muted`、`rule`)
- `app/views/shared/_delete_button.html.erb`、`_video_link.html.erb`、`_alias_fields.html.erb`、`_alias_row.html.erb`、`_self_demotion_warning.html.erb`
- `app/views/manage/scenarios/index.html.erb`、`_scenarios.html.erb`、`new.html.erb`
- `app/views/people/_alias_row.html.erb`

後ろの 2 行に挙げた 4 ファイルは、今の時点で到達しない。
`manage/scenarios` にはルートがなく、`people/_alias_row` は `shared/_alias_fields` が `shared/alias_row` を描画するため呼ばれない。
`manage/groups/show.html.erb` と `edit.html.erb` は明示的な描画元こそ無いが、`Manage::GroupsController` が暗黙に描画するため残す。

## 検証手順

各移行 PR で次を行う。

移行した画面のトップレベルテンプレートでは、`content_for :ui_theme, "dark"` を設定する。
同時に、その画面を legacy content contrast の監査対象から外し、画面全体の axe 検査へ移す。

1. `bin/rspec` と `prek run --all-files`
2. 対象画面の system spec に axe のチェックを入れ、コントラストとラベルの関連付けを機械で確認する
3. 320px、768px、1280px 相当の幅で、横方向のはみ出し、読み順、タップ領域を目視する
4. 追加した部品について、通常、hover、focus、active、disabled、error、danger の各状態を確認する。該当する部品では長い文言と空状態も確認する

最後のタスクで、画面間の差異とキーボード操作を横断的に確認する。

## 詰まりそうな箇所

**新旧トークンの併存。**
タスク 1 から 11 までのあいだ、`@theme` に 2 組のトークンが並ぶ。
移行済みかどうかで使い分けるため、レビューで見落としやすい。

**共有部分テンプレートの差し替え。**
`shared/_delete_button` はタスク 3、4、6、8、9、10 の画面から、`_video_link` はタスク 4 と 6 から、`_alias_fields` はタスク 8 と 9 から、`_self_demotion_warning` はタスク 8 と 10 から使われている。
旧ファイルは書き換えず、呼び出し側を新部品へ差し替える。

**シナリオ一覧の表示切り替え。**
`scenarios/index.html.erb` に「表形式」と「ジャケット」のトグルがあり、`_table` は `overflow-x-auto` と `min-w-3xl` の表になっている。
表をスマートフォンでカードへ切り替えると、狭い画面では両モードの表示が同じになる。
タスク 3 で、狭い画面ではトグル自体を隠すか、表形式のカードに別の情報を出すかを決める。

**危険操作と検証エラーの色。**
デザインサンプルにこの 2 色がない。
タスク 1 で背景に対して WCAG 2.2 AA を満たす値を決め、以降のタスクはそれを使う。

**境界の色。**
サンプルの `#35404e` は面に対するコントラストが 3 に届かない。
面どうしの色差も 1.1 から 1.2 しかないため、面の塗り分けでは代用できない。
タスク 1 で、境界だけが輪郭を示す部品のための明るい境界色を別に用意する。

**重なり順のトークン。**
Tailwind v4 の `@theme` には z-index の名前空間がない。
素のカスタムプロパティとして持ち、任意値記法で参照する。
