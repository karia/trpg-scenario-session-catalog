# 文字サイズの階層と一覧の圧縮

[ADR-0003](../adr/0003-type-scale.md) の 6 段の文字サイズを全画面に適用する。
あわせてシナリオ一覧を詰め、スマートフォンの 1 画面に入るタイトルを増やす。

一覧からは状態と入手先を外す。
どちらもシナリオ詳細に同じ情報があり、一覧で比べる用途が無い。
スマートフォンのカードは項目ごとの見出しを置かず、タイトル、作者、システム、人数と時間の順に積む。
作者を本文の段と本文の色、システムを補助情報の段と補助情報の色にし、見出しが無くても主従が読めるようにする。

## 変更するファイル

### トークンと既定値

- `app/assets/tailwind/application.css` — `@theme` に 5 段を追加し、`@layer base` の `body` に本文の段を既定として指定

### 共通部品とヘルパー

- `app/helpers/ui_helper.rb` — 入力欄のクラス列を入力の段へ
- `app/views/shared/ui/*.html.erb` — ボタン、ナビゲーション、見出し、カード、フォーム部品の文字サイズを段へ。`leading-*` を外す
- `app/javascript/controllers/toast_controller.js` — 通知の文字サイズを段へ

### 画面

- `app/views/layouts/*.html.erb` — サイト名を項目名の段に固定し、幅による切り替えを外す
- `app/views/scenarios/_table.html.erb` — 状態と入手先の列を削除
- `app/views/shared/ui/_scenario_card.html.erb` — 表形式のカードを見出しの無い 4 行構成へ。状態と入手先を削除
- `app/views/**/*.html.erb` — 残る文字サイズ指定を段へ置き換え。あらすじ、オススメポイント、準備情報、メモ、新規登録の説明だけ `leading-relaxed` を残す

### spec

- `spec/assets/ui_tokens_spec.rb` — 6 段の定義と `body` の既定を確認。ビューとヘルパーに Tailwind の文字サイズが残っていないことを確認
- `spec/requests/scenario_list_views_spec.rb` — 状態と入手先が一覧に出ないことを確認。状態の表示を前提にした例は削除

## 作業順序

1. spec を先に書き換え、落ちることを確かめる
2. トークンと `body` の既定を追加する
3. 共通部品を置き換える
4. 一覧の表とカードを組み替える
5. 残りの画面を置き換える
6. `bin/rails tailwindcss:build` の後に system spec を流す

## 検証

- `bin/rspec`。system spec は Chrome を用意して流す
- 幅 320px と 402px で、ヘッダーが 1 段に収まること
- 幅 402px で、シナリオ一覧の 1 画面に入るタイトル数
- 詳細画面で、あらすじと本文が 15px で描画されること

## 詰まりそうな箇所

| 箇所 | 注意点 |
| --- | --- |
| ヘッダー | サイト名 17px とボタン 15px の合計が、幅 320px で約 2px はみ出す計算になっている。ボタンの左右の余白で吸収する |
| `leading-*` の残り | `text-ui-*` の行の高さは `--tw-leading` があると負ける。置き換えた要素に `leading-*` が残っていないかを確認する |
| system spec の CSS | `bin/rspec` はビルド済みの CSS を読む。クラスを変えたら先にビルドする |
