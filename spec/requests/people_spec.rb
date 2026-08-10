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

    it "does not let the person change their own group membership" do
      group = create(:group)
      sign_in_as person

      patch person_path(person), params: { person: { display_name: "本人", group_ids: [ group.id ] } }

      expect(person.reload.groups).to be_empty
    end

    it "lets an admin change group membership from the admin screen" do
      group = create(:group)
      sign_in_as create(:person, roles: %w[admin])

      patch manage_person_path(person), params: { person: { display_name: "本人", group_ids: [ group.id ] } }

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
  end

  describe "icon uploads" do
    def upload(content, type, name)
      Rack::Test::UploadedFile.new(StringIO.new(content), type, original_filename: name)
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
  end
end
