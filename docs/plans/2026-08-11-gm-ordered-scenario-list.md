# シナリオ一覧のデフォルト表示順をGMが決める (issue #41)

一覧のデフォルト順を、GMが「シナリオの管理」画面でドラッグ＆ドロップして決めた並び (`scenarios.position`) にする。
公開側の見出しクリックによる並べ替えをやめ、表の右上に並び順のプルダウンを置く。

並び順は1つの `order` パラメータで持つ。
`<select>` は値を1つしか送れないため、キーと向きを別のパラメータに分けるとプルダウン1つでは表せない。

おすすめ度 (`recommendation`) は並び順の材料ではなくなる。
列とデータは残し、編集画面の入力欄だけを外す。
切り戻す可能性がなくなった段階で列を削除するため、モデルにTODOを残す。

## 変更するファイル

### スキーマとデータ移行

- `db/migrate/*_add_position_to_scenarios.rb` — `position` を追加し、既存行を `recommendation DESC NULLS LAST, title` の順で 1 から埋めて NOT NULL にする
- `db/schema.rb`

### モデルと並び順

- `app/models/scenario.rb` — `recommended_first` を `gm_ordered` に置き換える。作成時に末尾の position を振る。`recommendation` にTODOを付ける
- `app/queries/scenario_listing.rb` — `sort` / `direction` を `order` 1つにまとめ、既定を `gm_ordered` にする

### 公開側の表示

- `app/views/scenarios/index.html.erb` — 表の右上に並び順のプルダウンを置く
- `app/views/scenarios/_table.html.erb` — 見出しのソートリンクを外す
- `app/helpers/scenarios_helper.rb` — `scenario_sort_link` / `scenario_sort_order` を外し、プルダウンの選択肢を作る
- `app/javascript/controllers/auto_submit_controller.js` — 新規。選択が変わったら送信する

### 管理側の並べ替え

- `config/routes.rb` — `manage/scenarios` に collection の `reorder` を足す
- `app/controllers/manage/scenarios_controller.rb` — `reorder`。一覧を position 順にする
- `app/policies/scenario_policy.rb` — `reorder?`
- `app/views/manage/scenarios/index.html.erb` — 行を掴めるようにし、トーストの置き場所を作る
- `app/javascript/controllers/sortable_controller.js` — 新規。並べ替えて即座に送る
- `app/javascript/controllers/toast_controller.js` — 新規。右下に数秒出す

### 編集画面

- `app/views/manage/scenarios/_form.html.erb` — おすすめ度の入力欄を外す
- `app/controllers/manage/scenarios_controller.rb` — 許可パラメータから `recommendation` を外す

### ドキュメント

- `CLAUDE.md` — おすすめ度と並び順に関する約束を書き換える

## 作業順序

1. 計画をcommitする
2. position のスキーマ変更。移行後の並びを固定するspecを先に書く
3. モデルの並び順と作成時の position。specを先に書く
4. 管理画面の `reorder`。誰が叩けるかをrequest specで先に固定してから実装する
5. 管理画面のドラッグ＆ドロップとトースト
6. 公開側のプルダウン。既存のソートspecを `order` パラメータに書き換えてから実装する
7. おすすめ度を編集画面から外す
8. `bin/ci`

## 検証

- `bin/rspec`
- 移行後の値は `spec/migrations/` のspecで確かめる。既存specと同じく `down` してから旧形式の行を入れ、`up` の結果を見る
- `reorder` は編集エリアであるため、未ログイン・Person未紐づけ・権限なしのいずれも404であることをrequest specで固定する
- ドラッグ＆ドロップ自体はCapybaraが `rack_test` のため自動テストの対象外。サーバ側の契約 (行に付く属性と `reorder` の応答) をrequest specで固定し、操作は手元で確認する
- `bin/ci`

## 詰まりそうな箇所

- 一覧のspecは「レスポンスに `recommendation` の文字列が出ない」ことを見ている。プルダウンの値にこの語を使わない
- `position` に一意制約を付けない。並べ替えの途中で重複するため、順序は `position, id` で決める
- `reorder` はJSONではなくフォーム形式で受ける。CSRFトークンを載せないと422になる
- 列の追加のみで削除がないため、展開はJobの後にDeploymentを出す通常手順で足りる
