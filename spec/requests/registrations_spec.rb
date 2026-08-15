require "rails_helper"

RSpec.describe "Registrations" do
  it "explains the registration steps and provides Google and Discord sign-in" do
    get new_registration_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Discord連携済みのサーバーに参加していない場合")
    expect(response.body).to include("下記のボタンを押してGoogleまたはDiscordでログインする")
    expect(response.body).to include("プロフィールを提供してよいか認証先に聞かれるので許可する")
    expect(response.body).to include("管理者に連絡して許可してもらうのを待つ")
    expect(response.body).to include("他の参加サーバーの情報は取得しません")
    expect(response.body).to include("管理者以外の人に表示されることはありません")

    form = response.body.scan(%r{<form[^>]*action="/auth/google_oauth2".*?</form>}m)
      .find { |candidate| candidate.include?("Google でログイン") }
    expect(form).to include('method="post"')
    expect(form).to include('data-turbo="false"')
    expect(form).to include("Google でログイン")

    discord_form = response.body.scan(%r{<form[^>]*action="/auth/discord".*?</form>}m)
      .find { |candidate| candidate.include?("Discord でログイン") }
    expect(discord_form).to include('method="post"')
    expect(discord_form).to include('data-turbo="false"')
    expect(discord_form).to include("Discord でログイン")

    buttons = Capybara.string(response.body).find("div.flex.justify-center.gap-3")
    expect(buttons).to have_button("Google でログイン")
    expect(buttons).to have_button("Discord でログイン")
  end

  it "shows an approval request on every page while the account is unlinked" do
    sign_in_as create(:user, person: nil)

    get root_path

    expect(response.body).to include("管理者に連絡して、メンバー登録を依頼してください")
  end

  it "does not show the approval request to an approved member" do
    sign_in_as create(:person)

    get root_path

    expect(response.body).not_to include("メンバー登録を依頼してください")
  end
end
