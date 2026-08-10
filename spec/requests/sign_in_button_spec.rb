require "rails_helper"

RSpec.describe "The sign-in button" do
  # Turbo はフォーム送信を fetch に置き換えるため、Google への cross-origin リダイレクトを
  # 追えず、押しても何も起きなくなる。ブラウザに素の送信をさせる必要がある。
  it "opts out of Turbo so the browser follows the redirect to Google" do
    get root_path

    form = response.body[%r{<form[^>]*action="/auth/google_oauth2".*?</form>}m]

    expect(form).to be_present
    expect(form).to include('data-turbo="false"')
  end

  # トークンそのものは test 環境が forgery protection を切っているため出ない。
  # 開始を POST に限る点は spec/requests/sessions_spec.rb が GET で 404 を返すことで固定している。
  it "submits over POST, so another site cannot start the flow with a link" do
    get root_path

    form = response.body[%r{<form[^>]*action="/auth/google_oauth2"[^>]*>}]

    expect(form).to include('method="post"')
  end

  it "is not shown once signed in" do
    sign_in_as create(:user, person: nil)

    get root_path

    expect(response.body).not_to include('action="/auth/google_oauth2"')
  end
end
