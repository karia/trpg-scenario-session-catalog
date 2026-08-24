require "rails_helper"

RSpec.describe "The sign-in button" do
  it "shows separate registration and sign-in actions to signed-out visitors" do
    get root_path

    # 元いた画面へ戻すため origin を引き継ぐ。
    expect(response.body).to include(%(href="#{new_registration_path}?origin=%2F"))
    expect(response.body).to include(">新規登録</a>")
    expect(response.body).to include(">Discordでログイン</button>")
  end

  # Turbo はフォーム送信を fetch に置き換えるため、Google への cross-origin リダイレクトを
  # 追えず、押しても何も起きなくなる。ブラウザに素の送信をさせる必要がある。
  it "opts out of Turbo so the browser follows the redirect to Google" do
    get new_registration_path

    form = response.body[%r{<form[^>]*action="/auth/google_oauth2".*?</form>}m]

    expect(form).to be_present
    # form 側に置く。submitter 側でも Turbo 8 は見るが、バージョン差の影響を受けない。
    expect(form[%r{<form[^>]*>}]).to include('data-turbo="false"')
  end

  # トークンそのものは test 環境が forgery protection を切っているため出ない。
  # 開始を POST に限る点は spec/requests/sessions_spec.rb が GET で 404 を返すことで固定している。
  it "submits over POST, so another site cannot start the flow with a link" do
    get new_registration_path

    form = response.body[%r{<form[^>]*action="/auth/google_oauth2"[^>]*>}]

    expect(form).to include('method="post"')
  end

  it "passes the current URL through the sign-in flow" do
    # 動的に変わるのはヘッダーの Discord と、新規登録ページが引き継ぐ origin の 2 つ。
    get root_path(order: "title_desc")

    form = response.body[%r{<form[^>]*action="/auth/discord".*?</form>}m]

    expect(form).to include(%(name="origin" value="/?order=title_desc"))

    get new_registration_path(origin: "/?order=title_desc")

    google = response.body[%r{<form[^>]*action="/auth/google_oauth2".*?</form>}m]

    expect(google).to include(%(value="/?order=title_desc"))
  end

  it "ignores an origin that points off-site" do
    get new_registration_path(origin: "//evil.example.com/")

    form = response.body[%r{<form[^>]*action="/auth/google_oauth2".*?</form>}m]

    expect(form).to include(%(value="#{root_path}"))
    expect(form).not_to include("evil.example.com")
  end

  # Chrome は form-action をリダイレクト先にも当てる。self だけだと押しても Google へ進めない。
  it "allows the sign-in redirect to Google in form-action" do
    get root_path

    directive = response.headers["Content-Security-Policy"][/form-action [^;]+/]

    expect(directive).to include("https://accounts.google.com")
    expect(directive).to include("https://discord.com")
  end

  it "is not shown once signed in" do
    sign_in_as create(:user, person: nil)

    get root_path

    expect(response.body).not_to include('action="/auth/discord"')
    expect(response.body).not_to include(new_registration_path)
  end
end
