# シナリオ一覧の操作をツールバーとトレイへまとめる

一覧より上の見出しと操作が、スマートフォンのファーストビューの 6 割を占めている。
操作を 1 行のツールバーにまとめ、絞り込みの条件は下から開くトレイへ移す。

- 見出しは「シナリオ一覧」に縮め、所持者と件数は補助情報の 1 行に回す。`<title>` は所持者を含む今の文言のまま残す
- 並び順は、select を変えた時点で一覧へ反映する。一覧を差し替えた後は、フォーカスを select に戻す
- 絞り込みは、トレイで条件を選んで「適用する」でまとめて反映する。スマートフォンでは 1 条件ごとの反映よりまとめて反映するほうが使いやすい（[Mobile Faceted Search with a Tray](https://www.nngroup.com/articles/mobile-faceted-search/)）
- 適用中の条件は、ツールバーの下に 1 条件ずつ外せるチップで並べる
- 表示の切り替えは、見出しの行へアイコンで置く

## 変更するファイル

### 画面

- `app/views/scenarios/index.html.erb` — 見出しの行、件数、ツールバー、適用中の条件のチップ
- `app/views/scenarios/_filter_dialog.html.erb` — 絞り込みのトレイ。人数はラジオボタン、システムと作者はチェックボックス、作者の追加は候補付きの入力欄
- `app/helpers/ui_helper.rb` — `ui_collection_checkboxes` に選択状態と空値の送信有無を渡せるようにする

### Stimulus

- `app/javascript/controllers/dialog_controller.js` — トレイの開閉。入力エラーを返したときは開いた状態で描画する
- `app/javascript/controllers/frame_focus_controller.js` — Turbo Frame の差し替え後にフォーカスを戻す
- `app/javascript/controllers/filter_panel_controller.js`、`author_filter_controller.js`、`app/views/shared/ui/_filter_panel.html.erb` — 呼び出し元が無くなるため削除

### spec

- `spec/requests/scenario_list_sort_and_filter_spec.rb` — トレイの入力部品、適用中の条件のチップ、並び順の自動送信と JavaScript が無いときの送信ボタン
- `spec/requests/scenario_list_views_spec.rb` — 見出しと件数の行
- `spec/system/scenario_list_responsive_spec.rb` — トレイの開閉と適用、並び順の変更後のフォーカス、トレイを開いた状態の axe

## 作業順序

1. request spec を先に書き換え、落ちることを確かめる
2. ヘルパーと Stimulus コントローラを足す
3. 一覧の見出し、ツールバー、トレイ、チップを組む
4. 使われなくなった部品を削除する
5. system spec を書き換え、`bin/rails tailwindcss:build` の後に流す

## 検証

- `bin/rspec`。system spec は Chrome を用意して流す
- 幅 402px と 320px で、見出しの行とツールバーが崩れないこと
- 幅 402px で、ファーストビューに入るタイトル数
- キーボードだけで、トレイを開く、条件を選ぶ、適用する、閉じるを行えること

## 詰まりそうな箇所

| 箇所 | 注意点 |
| --- | --- |
| フォーカス | トレイと select はどちらも Turbo Frame の中にあり、反映のたびに差し替わる。差し替え前のフォーカス先を覚えておき、トレイから適用したときは絞り込みボタンへ戻す |
| チェックボックスの空値 | `collection_check_boxes` は既定で空の hidden を送る。GET の URL に空の `[]` が並ばないよう、トレイでは送らない |
| 作者の入力エラー | 候補に無い名前で適用すると、エラーをトレイの中に出す必要がある。トレイを開いた状態で描画する |
