require "rails_helper"

RSpec.describe "Manage::Users" do
  let(:admin) { create(:person, roles: %w[admin], display_name: "管理者") }

  describe "changing the link of the account you are signed in with" do
    it "asks for confirmation before dropping the link and stays unchanged" do
      user = sign_in_as create(:user, provider: "discord", uid: "1", person: admin)

      patch manage_user_path(user), params: { user: { person_id: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("管理者")
      expect(user.reload.person).to eq(admin)
    end

    it "goes through once the warning is acknowledged" do
      user = sign_in_as create(:user, provider: "discord", uid: "1", person: admin)

      patch manage_user_path(user), params: { user: { person_id: "" }, confirm_self_demotion: "admin" }

      expect(response).to redirect_to(manage_user_path(user))
      expect(user.reload.person).to be_nil
    end

    it "keeps the submitted choice on the re-rendered form" do
      user = sign_in_as create(:user, provider: "discord", uid: "1", person: admin)
      other = create(:person, display_name: "権限のない人")

      patch manage_user_path(user), params: { user: { person_id: other.id } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Capybara.string(response.body).find("#user_person_id").value).to eq(other.id.to_s)
      expect(user.reload.person).to eq(admin)
    end

    it "does not warn when the new link keeps the same roles" do
      user = sign_in_as create(:user, provider: "discord", uid: "1", person: admin)
      another_admin = create(:person, roles: %w[admin], display_name: "もうひとりの管理者")

      patch manage_user_path(user), params: { user: { person_id: another_admin.id } }

      expect(response).to redirect_to(manage_user_path(user))
      expect(user.reload.person).to eq(another_admin)
    end
  end

  describe "changing the link of another account" do
    it "does not warn when the account is a different provider of your own person" do
      sign_in_as create(:user, provider: "discord", uid: "1", person: admin)
      google_user = create(:user, provider: "google_oauth2", uid: "2", person: admin)

      patch manage_user_path(google_user), params: { user: { person_id: "" } }

      expect(response).to redirect_to(manage_user_path(google_user))
      expect(google_user.reload.person).to be_nil
    end

    it "does not warn when the account belongs to someone else" do
      sign_in_as create(:user, provider: "discord", uid: "1", person: admin)
      other_admin = create(:person, roles: %w[admin], display_name: "別の管理者")
      other_user = create(:user, provider: "discord", uid: "3", person: other_admin)

      patch manage_user_path(other_user), params: { user: { person_id: "" } }

      expect(response).to redirect_to(manage_user_path(other_user))
      expect(other_user.reload.person).to be_nil
    end
  end
end
