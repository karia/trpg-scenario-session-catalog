# Phase 2: 認証と権限

**目的**: Google 認証でログインできるようにし、Person、権限、グループという認可の土台を用意する。

**依存**: Phase 0。Phase 1 とは並行して進められる。

**設計**: [ADR-0001](../adr/0001-application-architecture.md)

## データモデル

- `Person`: 管理者が作る人物。表示名、アイコン（Active Storage）、X のアカウント名
- `User`: Google アカウント。`google_uid`、`email`、`person_id`（NULL 可）
- `PersonRole`: Person に対する権限。管理者、GM、プレイヤーを複数付与できる
- `Group`: グループ。名前を持つ
- `GroupMembership`: Person と Group の多対多

`User` はログインに必要な情報だけを持つ。
表示名や権限は Person 側に置く。

Person に紐づいていない `User` は、ログイン済みだが公開エリアしか見られない状態を表す。
これは例外ではなく通常の状態として扱い、登録直後のユーザーは必ずこの状態を通る。

## 作成するファイル

- マイグレーション: `people`、`users`、`person_roles`、`groups`、`group_memberships`
- モデル: `Person`、`User`、`PersonRole`、`Group`、`GroupMembership`
- `config/initializers/omniauth.rb`
- `app/controllers/sessions_controller.rb`
- `app/controllers/concerns/authentication.rb`: `current_user` と `current_person`、ログイン必須の before_action
- `app/policies/application_policy.rb`
- `app/avo/resources/` に Person、User、Group のリソース
- Avo の認可設定
- `app/views/shared/_analytics.html.erb` と `_ads.html.erb` の判定を実装に差し替える
- spec: モデルスペック、`spec/requests/sessions_spec.rb`、認可のスペック

## 作業順序

1. `Person` と `PersonRole` のモデルスペックを書き、失敗を確認してから実装する
2. `Group` と `GroupMembership` のモデルと関連
3. `User` と Person への 1 対 1 の関連。`google_uid` の一意性をテストで固定する
4. OmniAuth の設定とコールバック。テストは `OmniAuth.config.test_mode` で行う
5. ログイン、ログアウト、未ログイン時のリダイレクトのリクエストスペックを書いてから実装する
6. `current_person` を用意する。Person 未紐づけの `User` では nil を返す
7. `ApplicationPolicy` を置き、ログイン必須エリアの既定を拒否にする
8. Avo を管理者にだけ開く。GM に開く範囲はリソース単位で決める
9. 管理画面で `User` を `Person` に紐づける操作を作る
10. 管理画面でグループを作り、Person を所属させる操作を作る
11. 解析タグと広告タグの描画判定を、ログイン状態を見る実装に差し替える

## 検証手順

- `bin/rspec` がすべて成功する
- Google でログインでき、ログアウトできる
- 初回ログインのユーザーが Person 未紐づけで作られる
- Person 未紐づけのユーザーが、ログイン必須のパスにアクセスすると弾かれる
- 管理者が Person を作り、`User` に紐づけると、そのユーザーがログイン必須エリアに入れる
- 管理者以外が `/avo` にアクセスすると 404 または 403 を返す
- ログイン中のページに解析タグと広告タグが出ない。未ログインでは出る

## 詰まりそうな箇所

**OAuth クライアントの登録**。
リダイレクト URI は開発と本番で別に登録する。
クライアント ID とシークレットは環境変数で渡し、リポジトリに置かない。

**CSRF 対策**。
omniauth-rails_csrf_protection を入れ、認証の開始を POST に限定する。
GET のままだと、外部サイトからログインを誘発できる。

**権限の置き場所**。
権限は Person に付ける。
`User` に権限を持たせると、アカウントを差し替えたときに権限が失われる。

**Avo と Pundit のクラス名解決**。
Avo は Pundit のポリシークラスをモデル名から引く。
Avo のリソース名とモデル名を揃えておかないと、意図しないポリシーが当たる。

**Phase 1 との合流点**。
解析タグと広告タグの描画判定は Phase 1 が用意した関数を差し替える形にする。
Avo の有効化も Phase 1 で無効にしたルーティングを開く形になる。
どちらも Phase 1 の完了後にまとめて行う。

**管理者の初期投入**。
最初の管理者を作る手段が要る。
seed か rake タスクで、指定した `google_uid` の `User` を Person に紐づけて管理者権限を与える。
