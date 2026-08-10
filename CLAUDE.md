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
| CI と同じ一式 | `bin/ci`（PR を出す前に通す） |
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
インフラ側のリポジトリで次の順に行う。

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

### 公開リポジトリとして

- public repo である。クラスタ側の資格情報とリソース識別子を持ち込まない
- シナリオの実データは git に置かない。書式は `db/seeds/scenarios.example.yml`、投入先は `SCENARIOS_SEED_FILE` で差し替える

### 設定と実行

[The Twelve-Factor App](https://12factor.net/) に従う。とくに次の 4 つを崩さない。

- 設定はすべて環境変数から読む。Rails credentials は使わない（`config/master.key` は存在しない）。本番で欠けては困る変数は `config/initializers/required_env.rb` に足し、起動時に落とす
- ログは標準出力にだけ出す（`config/environments/production.rb`）。ファイルへの書き出しや収集サービスへの直接送信を足さない。収集はクラスタ側に任せる
- マイグレーションはリリース時の Job が実行する。`bin/docker-entrypoint` にも起動時フックにも入れない。手順は「データベースを変える」にある
- 本番では状態をプロセスの外に置く。アップロードは Active Storage 経由で MinIO、キャッシュとキューは Solid Cache / Solid Queue の DB に入れる（`config/environments/production.rb`）。ローカルディスクとプロセス内メモリに残すと、Pod の入れ替えで消える

### 認可

- 認可は Pundit に寄せる。`ApplicationPolicy` は既定で拒否し、`Scope` は空集合を返す
- 権限が無い相手には 403 ではなく 404 を返す。隠している画面の存在を教えない
- 権限は Person に付く。`User` は認証に要る情報だけを持つ。`pundit_user` は `current_person`
- セッションの可視性は `PlaySessionPolicy::Scope` にだけ書く。一覧、詳細、シナリオ詳細の履歴が同じものを通る
- 準備情報は `ScenarioPolicy#show_preparation_note?` が真のときだけ本文をレスポンスに載せる。CSS では隠さない
- プロフィールの編集は本人と管理者。グループ所属は管理画面（管理者のみ）でしか変えられない
- 誰に何が見えるかを固定する spec の置き場所は決まっている。役割ごとの可否は `spec/policies/authorization_matrix_spec.rb` の一覧に足し、画面から見えるかどうかは `spec/requests/` に足す

### ドメイン

- プレイヤーは全員が持つため保存しない。`Person#player?` は常に真で、付け外しできない
- 最初の管理者は `bin/rails admin:grant EMAIL=... NAME=...` で作る。管理画面からは作れない
- おすすめ度は編集画面にだけ出す。表示はせず並び順の材料として持つ

### 進め方

TDD、commit の分け方、pre-commit の扱いは [README の「変更を出す」](README.md#変更を出す) にある。加えて次を守る。

- 作業は `main` から切った worktree で行う。元のディレクトリは `main` のまま残す
- PR を作ったら必ずサブエージェントで第三者レビューを実行し、GitHub の行コメントとして投稿する。規模を問わず必須で、実施の可否は尋ねない
- レビューが返ったら内容を精査し、対応・非対応を PR 上で1件ずつ返信する
- マージは依頼者が行う。こちらでは merge しない
- 会話は日本語。commit と PR の title/description は英語

### コードを書くとき

- ソースに複数行コメントを書かない。書くのは、コードから読み取れない背景や理由に限る
