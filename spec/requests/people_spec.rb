require "rails_helper"

RSpec.describe "People" do
  let(:person) { create(:person, display_name: "本人") }
  let(:other) { create(:person, display_name: "別の人") }

  describe "viewing" do
    it "is closed to a visitor who has not signed in" do
      get person_path(person)

      expect(response).to have_http_status(:not_found)
    end

    it "is closed to an account that is not linked to a person" do
      sign_in_as create(:user, person: nil)

      get person_path(person)

      expect(response).to have_http_status(:not_found)
    end

    it "is open to any signed-in member" do
      sign_in_as other

      get person_path(person)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("本人")
    end

    it "lists the aliases" do
      person.person_aliases.create!(name: "べつの名前", context: "とあるサーバ")
      sign_in_as other

      get person_path(person)

      expect(response.body).to include("べつの名前", "とあるサーバ")
    end

    it "does not expose hidden aliases" do
      person.person_aliases.create!(name: "公開名", visible: true)
      person.person_aliases.create!(name: "秘密名", visible: false)
      sign_in_as other

      get person_path(person)

      expect(response.body).to include("公開名")
      expect(response.body).not_to include("秘密名")
    end
  end

  describe "editing" do
    it "lets the person edit their own profile" do
      sign_in_as person

      patch person_path(person), params: { person: { display_name: "改名した本人", x_account: "karia" } }

      expect(person.reload.display_name).to eq("改名した本人")
    end

    it "refuses to open someone else's edit form" do
      sign_in_as other

      get edit_person_path(person)

      expect(response).to have_http_status(:not_found)
    end

    it "opens the edit form for the person themselves" do
      sign_in_as person

      get edit_person_path(person)

      expect(response).to have_http_status(:ok)
    end

    it "refuses someone else" do
      sign_in_as other

      patch person_path(person), params: { person: { display_name: "乗っ取り" } }

      expect(response).to have_http_status(:not_found)
      expect(person.reload.display_name).to eq("本人")
    end

    it "lets an admin edit anyone" do
      sign_in_as create(:person, roles: %w[admin])

      patch person_path(person), params: { person: { display_name: "管理者が直した" } }

      expect(person.reload.display_name).to eq("管理者が直した")
    end

    it "lets an admin edit profile aliases and management fields in the same form" do
      group = create(:group)
      sign_in_as create(:person, roles: %w[admin])

      patch person_path(person), params: {
        person: {
          display_name: person.display_name,
          roles: [ "gm" ],
          manual_group_ids: [ group.id ],
          person_aliases_attributes: [ { name: "管理者が追加した別名", visible: "1" } ]
        }
      }

      person.reload
      expect(person.roles).to include("gm")
      expect(person.groups).to eq([ group ])
      expect(person.person_aliases.map(&:name)).to include("管理者が追加した別名")
    end

    it "does not let the person change their own group membership" do
      group = create(:group)
      sign_in_as person

      patch person_path(person), params: { person: { display_name: "本人", manual_group_ids: [ group.id ] } }

      expect(person.reload.groups).to be_empty
    end

    it "lets an admin change group membership from the admin screen" do
      group = create(:group)
      sign_in_as create(:person, roles: %w[admin])

      patch person_path(person), params: { person: { display_name: "本人", manual_group_ids: [ group.id ] } }

      expect(person.reload.groups).to eq([ group ])
    end

    it "adds and removes aliases from the profile form" do
      sign_in_as person

      patch person_path(person), params: {
        person: {
          display_name: "本人",
          person_aliases_attributes: [ { name: "A", context: "サーバ1" }, { name: "B" } ]
        }
      }

      expect(person.reload.person_aliases.map(&:name)).to contain_exactly("A", "B")

      alias_to_drop = person.person_aliases.find_by(name: "B")
      patch person_path(person), params: {
        person: { display_name: "本人", person_aliases_attributes: [ { id: alias_to_drop.id, _destroy: "1" } ] }
      }

      expect(person.reload.person_aliases.map(&:name)).to eq([ "A" ])
    end

    it "lets the person choose a visible alias as their display name" do
      selected = person.person_aliases.create!(name: "新しい名前", visible: true)
      sign_in_as person

      patch person_path(person), params: {
        person: { display_name: "本人", display_alias_key: selected.id }
      }

      expect(person.reload.display_name).to eq("新しい名前")
      expect(selected.reload.name).to eq("本人")
    end

    it "keeps the context field available while editing aliases" do
      person.person_aliases.create!(name: "別名", context: "古いサーバ")
      sign_in_as person

      patch person_path(person), params: {
        person: {
          display_name: "本人",
          aliases_attributes: [ { id: person.person_aliases.sole.id, name: "別名", context: "新しいサーバ" } ]
        }
      }

      expect(person.reload.person_aliases.sole.context).to eq("新しいサーバ")
    end
  end

  describe "icon uploads" do
    def upload(content, type, name)
      Rack::Test::UploadedFile.new(StringIO.new(content), type, original_filename: name)
    end

    it "limits the icon picker to supported image formats" do
      sign_in_as person

      get edit_person_path(person)

      expect(Capybara.string(response.body))
        .to have_css('input[name="person[icon]"][accept="image/png,image/jpeg,image/webp"]')
    end

    # 1 人の不正なアップロードで、一覧を開いた全員が 500 になるのを防ぐ。
    it "refuses a file that is not an image, and leaves the member list working" do
      sign_in_as person

      patch person_path(person), params: {
        person: { display_name: "本人", icon: upload("not an image", "text/plain", "evil.txt") }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(person.reload.icon).not_to be_attached

      get people_path
      expect(response).to have_http_status(:ok)
    end

    it "accepts a PNG" do
      sign_in_as person

      patch person_path(person), params: {
        person: {
          display_name: "本人",
          icon: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/dot.png"), "image/png")
        }
      }

      expect(person.reload.icon).to be_attached
    end
  end

  describe "the member list" do
    it "is closed to a visitor who has not signed in" do
      get people_path

      expect(response).to have_http_status(:not_found)
    end

    it "shows every member to a signed-in member" do
      person
      sign_in_as other

      get people_path

      expect(response.body).to include("本人", "別の人")
    end

    it "carries no explanation under the title" do
      sign_in_as other

      get people_path

      expect(response.body).not_to include("ログインしている人だけが見られます")
    end
  end

  describe "dropping your own roles" do
    let(:admin) { create(:person, roles: %w[admin gm], display_name: "管理者") }

    before { create(:person, roles: %w[admin], display_name: "もうひとりの管理者") }

    it "asks for confirmation and keeps the roles" do
      sign_in_as admin

      patch person_path(admin), params: { person: { display_name: "管理者", roles: [ "gm", "" ] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("管理者権限を失い")
      expect(admin.reload.roles).to contain_exactly("admin", "gm")
    end

    it "warns about the GM role too" do
      sign_in_as admin

      patch person_path(admin), params: { person: { display_name: "管理者", roles: [ "admin", "" ] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("GM権限を失い")
      expect(admin.reload.roles).to contain_exactly("admin", "gm")
    end

    it "shows the submitted roles on the re-rendered form" do
      sign_in_as admin

      patch person_path(admin), params: { person: { display_name: "管理者", roles: [ "gm", "" ] } }

      page = Capybara.string(response.body)
      expect(page.find("#person_roles_admin")).not_to be_checked
      expect(page.find("#person_roles_gm")).to be_checked
    end

    it "goes through once the warning is acknowledged" do
      sign_in_as admin

      patch person_path(admin), params: {
        person: { display_name: "管理者", roles: [ "gm", "" ] }, confirm_self_demotion: "admin"
      }

      expect(response).to redirect_to(person_path(admin))
      expect(admin.reload.roles).to contain_exactly("gm")
    end

    it "warns again when the form drops a role the warning did not cover" do
      sign_in_as admin

      patch person_path(admin), params: {
        person: { display_name: "管理者", roles: [ "" ] }, confirm_self_demotion: "gm"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("管理者権限を失い")
      expect(admin.reload.roles).to contain_exactly("admin", "gm")
    end

    it "carries the acknowledged roles on the re-rendered form" do
      sign_in_as admin

      patch person_path(admin), params: { person: { display_name: "管理者", roles: [ "gm", "" ] } }

      expect(Capybara.string(response.body).find("#confirm_self_demotion", visible: false).value).to eq("admin")
    end

    it "does not warn when the roles are unchanged" do
      sign_in_as admin

      patch person_path(admin), params: {
        person: { display_name: "管理者", x_account: "karia", roles: [ "admin", "gm", "" ] }
      }

      expect(response).to redirect_to(person_path(admin))
      expect(admin.reload.x_account).to eq("karia")
    end

    it "does not warn when someone else loses a role" do
      sign_in_as admin
      target = create(:person, roles: %w[gm], display_name: "GM の人")

      patch person_path(target), params: { person: { display_name: "GM の人", roles: [ "" ] } }

      expect(response).to redirect_to(person_path(target))
      expect(target.reload.roles).to be_empty
    end

    it "does not warn when a member without roles edits their own profile" do
      member = create(:person, display_name: "ただの人")
      sign_in_as member

      patch person_path(member), params: { person: { display_name: "ただの人", x_account: "member" } }

      expect(response).to redirect_to(person_path(member))
      expect(member.reload.x_account).to eq("member")
    end
  end

  describe "deleting your own person" do
    let(:admin) { create(:person, roles: %w[admin], display_name: "管理者") }

    before { create(:person, roles: %w[admin], display_name: "もうひとりの管理者") }

    it "asks for confirmation and keeps the person" do
      sign_in_as admin

      delete person_path(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("管理者権限を失い")
      expect(Person.exists?(admin.id)).to be(true)
    end

    it "goes through once the warning is acknowledged" do
      sign_in_as admin

      delete person_path(admin), params: { confirm_self_demotion: "admin" }

      expect(response).to redirect_to(people_path)
      expect(Person.exists?(admin.id)).to be(false)
    end

    it "does not warn when someone else is deleted" do
      sign_in_as admin
      target = create(:person, roles: %w[gm], display_name: "GM の人")

      delete person_path(target)

      expect(response).to redirect_to(people_path)
      expect(Person.exists?(target.id)).to be(false)
    end
  end
end
