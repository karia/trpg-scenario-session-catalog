# シナリオ一覧のソートと絞り込み (issue #28)

一覧の見出しからソートし、上部のメニューから作者・システム・人数で絞り込めるようにする。
あわせて、人数と目安時間のスキーマを issue の指定に合わせる。

並び替えと絞り込みは、ADR-0001 が挙げる ransack ではなく、許可リスト方式の小さなクエリオブジェクトで組む。
作者とシステムは `has_many through` であり、ransack の `sort_link` から辿ると `SELECT DISTINCT ... ORDER BY authors.name` になって PostgreSQL が拒む。
重複行を避けるために相関サブクエリで並べるなら、gem を挟む利点が残らない。
この判断を残すなら、別途 ADR-0001 の更新が要る。

目安時間の丸めは、下限を切り捨て、上限を切り上げる。
目安の幅が移行で縮むと「実際は超えていた」が起きるため、広がる向きに寄せる。

## 変更するファイル

### スキーマとデータ移行

- `db/migrate/*_require_scenario_player_count_min.rb` — NULL を 1 で埋め、`player_count_min` を NOT NULL に。`player_count_note` を削除
- `db/migrate/*_convert_scenario_duration_to_hours.rb` — `duration_{min,max}_minutes` を `duration_{min,max}_hours` (decimal) へ変換して差し替え
- `db/schema.rb`
- `db/seeds.rb` / `db/seeds/scenarios.example.yml` / `spec/fixtures/scenarios_seed.yml`

### モデルと表示

- `app/models/scenario.rb` — 下限必須、上限任意、時間は 0.5 刻み
- `app/helpers/scenarios_helper.rb` — 人数と時間の表記。単位は「時間」に統一
- `app/helpers/structured_data_helper.rb` — JSON-LD の `timeRequired`
- `app/views/manage/scenarios/_form.html.erb` / `app/controllers/manage/scenarios_controller.rb` — 入力欄と許可パラメータ

### ソートと絞り込み

- `app/queries/scenario_search.rb` — 新規。許可リストで並び順と絞り込みを組み立てる
- `app/controllers/scenarios_controller.rb`
- `app/views/scenarios/index.html.erb` — 絞り込みメニュー
- `app/views/scenarios/_table.html.erb` — 見出しのソートリンク
- `app/helpers/scenarios_helper.rb` — ソートリンクと現在の並び順の表示

## 作業順序

1. 計画をcommitする
2. 人数のスキーマ変更。specを先に書き、移行後の値と検証を固定する
3. 目安時間のスキーマ変更。同じくspecを先に書く
4. 表示の追従 (helper、JSON-LD、編集フォーム、seed)
5. `ScenarioSearch` と絞り込みメニュー、見出しのソートリンク
6. `bin/ci`

## 検証

- `bin/rspec`
- 移行後の値は `spec/migrations/` のspecで確かめる。テストDBに対して migration を `down` してから旧形式の行を入れ、`up` の結果を見る
- 認可に触れないが、一覧は公開エリアであるため、絞り込みとソートを付けても `policy_scope` を通ることをrequest specで固定する
- `bin/ci`

## 詰まりそうな箇所

- 作者とシステムでのソートは相関サブクエリで組む。JOINすると1シナリオが作者の数だけ並ぶ
- `Arel.sql` に渡す文字列は定数の連結だけにする。paramsを混ぜるとBrakemanが正しく騒ぐ
- 列の削除を含むため、Jobでmigrateしてから新しいPodを出すまでの間、旧Podの書き込みが落ちる。展開手順をPRに書く
