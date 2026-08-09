# Phase 1: シナリオ公開エリア

**目的**: シナリオの一覧と詳細を、ログインなしで閲覧できる形で公開する。あわせて管理画面からシナリオを登録できるようにする。

**依存**: Phase 0。Phase 2 とは並行して進められる。

**設計**: [ADR-0001](../adr/0001-application-architecture.md)

## データモデル

既存のスプレッドシートの列を、次のように移す。

| スプレッドシートの列 | 移し先 |
| --- | --- |
| シナリオ名 | `Scenario#title` |
| システム | `GameSystem` との多対多。「CoC 6版&7版」のように 2 つ取る行がある |
| 作者 | `Author` との多対多。連名の行がある |
| URL | `PurchaseLink`。ラベルと任意の URL を持つ |
| PL人数 | `Scenario#player_count_min` と `#player_count_max`（いずれも NULL 可）、`#player_count_note` |
| 目安時間 | `Scenario#duration_min_minutes` と `#duration_max_minutes` |
| オススメ度 | `Scenario#recommendation`（1 から 5、NULL 可）と `Scenario#gm_experienced`（真偽値） |
| 参加可能キャラの制限 | `Scenario#character_restriction`（自由記述） |
| キャラシ提出期限 | `Scenario#character_sheet_deadline`（選択式） |
| 備考やオススメポイントなど | `Scenario#recommendation_note` |

スプレッドシートにない項目を要件から追加する。

- `Scenario#synopsis`: あらすじ
- `Scenario#preparation_note`: シナリオ準備情報。Phase 4 でネタバレ防止ボタンの背後に隠す
- ジャケット画像: Active Storage の添付
- `StreamLink`: おすすめの配信リンク。複数持つ

各列の値の癖を、スキーマ側で受け止める。

- 「制限なし」の PL人数は最小と最大の両方を NULL にし、補足を `player_count_note` に置く
- 「1人推奨」のように人数と含みが混ざる行があるため、数値と補足を別の列に分ける
- 「30分～60分」があるため、目安時間は分単位で持つ
- オススメ度は 3 つの状態を取る。星の付いた行は `recommendation` に 1 から 5 を入れる。「回したことない」の行は `gm_experienced` を false にし `recommendation` を NULL にする。空欄の行は `gm_experienced` を true のまま `recommendation` を NULL にする
- キャラシ提出期限は、前日、前々日、1 週間前、不要、備考参照の 5 つを列挙型にする。「-」と空欄は列挙値ではなく NULL として扱い、未設定と表示する
- 販売サイトの URL には、URL でない値（購入方法の説明）が入る行がある。`PurchaseLink#url` は NULL を許し、ラベルだけの登録を通す

## 作成するファイル

- マイグレーション: `game_systems`、`authors`、`scenarios`、`scenario_game_systems`、`scenario_authors`、`purchase_links`、`stream_links`
- モデル: 上記に対応する 7 クラス
- `app/controllers/scenarios_controller.rb`
- `app/views/scenarios/index.html.erb`、`show.html.erb` と部分テンプレート
- `app/views/scenarios/_play_session_history.html.erb` と `_preparation_note.html.erb`: 中身は空で置く。Phase 3 と Phase 4 がそれぞれ片方だけを埋める
- `app/policies/scenario_policy.rb`: Phase 0 が置いた `ApplicationPolicy` を継承し、閲覧だけを許す
- `app/controllers/manage/scenarios_controller.rb` ほか、編集画面のコントローラとビュー
- `app/views/layouts/application.html.erb`: メタタグ、解析タグ、広告タグの差し込み位置
- `app/views/shared/_analytics.html.erb`、`_ads.html.erb`
- `app/helpers/structured_data_helper.rb`: JSON-LD
- `config/sitemap.rb`
- spec: モデルスペック、`spec/requests/scenarios_spec.rb`、システムスペック 1 本

## 作業順序

1. `GameSystem` と `Author` のモデルスペックを書き、失敗を確認してから実装する
2. `Scenario` のマイグレーションとモデル。上の表の列を揃え、バリデーションのテストを先に書く
3. 多対多の関連と、`PurchaseLink`、`StreamLink` のテスト
4. 一覧と詳細のリクエストスペックを書いてから、コントローラとルーティングを実装する
5. 画面を組む。ここで frontend-design スキルを使う。詳細ページにはセッション履歴と準備情報の空の部分テンプレートを差し込んでおく
6. ジャケット画像を Active Storage で添付し、一覧用の variant を用意する
7. 編集画面を作る。認証が入るのは Phase 2 のため、この時点では HTTP Basic 認証で暫定的に塞ぐ。資格情報は環境変数で渡す
8. 作者、システム、販売リンク、配信リンク、ジャケット画像をまとめて編集できるフォームにする
9. 既存のスプレッドシートの内容を編集画面から入力する
10. meta-tags でタイトルと description、OGP を出す
11. シナリオ詳細に JSON-LD を出す
12. sitemap_generator でサイトマップを生成し、`robots.txt` から参照する
13. 解析タグと広告タグを部分テンプレートに切り出す

## 検証手順

- `bin/rspec` がすべて成功する
- 未ログインでシナリオ一覧とシナリオ詳細が 200 を返す
- 一覧から詳細へ遷移し、ジャケット画像、販売サイトリンク、配信リンクが表示される
- 詳細ページの HTML に JSON-LD が含まれ、構造化データテストツールで警告が出ない
- `/sitemap.xml` が生成され、公開シナリオの URL を列挙している
- Lighthouse の SEO スコアが 90 以上になる。実データを入れた後に測る
- 準備情報が、この時点ではどのユーザーにも表示されない
- Basic 認証なしで編集画面にアクセスすると 401 を返す

## 詰まりそうな箇所

**編集画面の暫定的な保護**。
Phase 1 の時点では管理者の概念がまだない。
一方で、SEO の検証には実データが要り、実データを入れるには編集画面が要る。
Phase 1 では HTTP Basic 認証で暫定的に塞ぎ、Phase 2 で Pundit による役割判定に差し替える。
認可のないまま公開経路に出すと、誰でもシナリオを編集できる。

**解析タグと広告タグのログイン判定**。
描画を分ける関数を Phase 1 で用意し、Phase 2 が入るまでは常に非ログインを返す実装にしておく。
Phase 2 側はこの関数の中身を差し替えるだけで済む。

**ジャケット画像の出どころ**。
販売サイトの商品画像をそのまま配信してよいかは、サイトごとに規約が異なる。
公開バケットへ置く前に確認する。

**既存データの取り込み**。
対象は 60 件強。
取り込み用の rake タスクを書くより、編集画面から手で入れるほうが早い。
スプレッドシートは列の値の揺れが大きく、パーサを書くと揺れの吸収に時間を取られる。
