# CLAUDE.md

セットアップと PR の出し方は [README](README.md) にある。ここには、作業中に迷う手順と、この repo の約束を書く。

## どこに何があるか

| 層 | 置き場所 | 補足 |
| --- | --- | --- |
| 公開エリア | `app/controllers/scenarios_controller.rb` ほか | 未ログインでも見える。SEO の対象はここだけ |
| ログイン必須エリア | `play_sessions` / `people` | `current_person` が nil なら入れない |
| 編集エリア | `app/controllers/manage/` | `Manage::BaseController` が入口を塞ぐ |
| 認可 | `app/policies/` | 判断はすべてここ。ビューやコントローラに条件を散らさない |

認証は Google のみ。`User` は Google アカウント、`Person` は人物で、1 対 1 で紐づく。
紐づいていない `User` は「ログイン済みだが公開エリアしか見えない」通常の状態。

## よく使う手順

| したいこと | コマンド |
| --- | --- |
| テスト | `bin/rspec` |
| 1 ファイルだけ | `bin/rspec spec/requests/scenarios_spec.rb:42` |
| 静的解析をまとめて | `prek run --all-files` |
| 開発サーバ | `bin/dev`（Puma と Tailwind の watch） |
| シナリオの投入 | `bin/rails db:seed`（冪等） |

Ruby と Node は mise で固定している。shims を PATH に置いていない環境では `mise exec --` を頭に付ける。

## データベースを変える

```bash
bin/rails generate migration AddFooToBar foo:string
bin/rails db:migrate          # 開発 DB に当て、db/schema.rb が更新される
bin/rails db:test:prepare     # テスト DB に schema.rb を流し直す
```

`db/schema.rb` は必ず commit する。テストは migration ではなく schema.rb から DB を作る。

**本番のマイグレーションはアプリの起動から切り離してある。** コンテナの entrypoint では走らない。
`yuno04-k3s` 側で次の順に行う。

1. migrate の Job と Deployment の**両方**のイメージを新しい digest に書き換える。Job は Deployment と別に digest を持つので、ここを忘れると古いコードのマイグレーションが走る
2. Job を `kubectl create -f` で流す。`generateName` なので `apply` では作れない。中身は `db:prepare`
3. Job の完走を確認してから Deployment を `apply` する

順序を逆にすると、新しいコードが古いスキーマに当たる。

破壊的な変更（列の削除、型の変更）は、読み書きの両方が新旧どちらのスキーマでも動く状態を経由させる。
Pod の入れ替え中は新旧が同時に動く。

## 手元の DB が壊れたら

```bash
docker compose down -v && docker compose up -d
bin/rails db:prepare && bin/rails db:test:prepare
```

テストは1例ごとにロールバックするので、通常は残留しない。
それでも実行順に依存して落ちるときだけ、トランザクション外で commit された行を疑う。

```bash
RAILS_ENV=test bin/rails runner 'puts Person.count'   # 0 でなければ残っている
```

## この repo の約束

- public repo である。クラスタ側の資格情報とリソース識別子を持ち込まない
- 設定はすべて環境変数から読む。Rails credentials は使わない（`config/master.key` は存在しない）
- 認可は Pundit に寄せる。`ApplicationPolicy` は既定で拒否し、`Scope` は空集合を返す
- 権限が無い相手には 403 ではなく 404 を返す。隠している画面の存在を教えない
- 権限は Person に付く。`User` は認証に要る情報だけを持つ。`pundit_user` は `current_person`
- プレイヤーは全員が持つため保存しない。`Person#player?` は常に真で、付け外しできない
- 最初の管理者は `bin/rails admin:grant EMAIL=... NAME=...` で作る。管理画面からは作れない
- セッションの可視性は `PlaySessionPolicy::Scope` にだけ書く。一覧、詳細、シナリオ詳細の履歴が同じものを通る
- 準備情報は `ScenarioPolicy#show_preparation_note?` が真のときだけ本文をレスポンスに載せる。CSS では隠さない
- プロフィールの編集は本人と管理者。グループ所属は管理画面（管理者のみ）でしか変えられない
- おすすめ度は編集画面にだけ出す。表示はせず並び順の材料として持つ
- シナリオの実データは git に置かない。書式は `db/seeds/scenarios.example.yml`、投入先は `SCENARIOS_SEED_FILE` で差し替える
- ソースに複数行コメントを書かない。書くのは、コードから読み取れない背景や理由に限る
