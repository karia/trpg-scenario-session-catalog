require "rails_helper"

RSpec.describe "Manage::People" do
  describe "access" do
    it "answers 404 to an anonymous visitor" do
      get manage_people_path

      expect(response).to have_http_status(:not_found)
    end

    it "answers 404 to a GM, who may edit content but not membership" do
      sign_in_as create(:person, roles: %w[gm])

      get manage_people_path

      expect(response).to have_http_status(:not_found)
    end

    it "lets an admin in" do
      sign_in_as create(:person, roles: %w[admin])

      get manage_people_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "as an admin" do
    before { sign_in_as create(:person, roles: %w[admin], display_name: "カーリア") }

    it "limits the icon picker to supported image formats" do
      person = create(:person)

      get edit_manage_person_path(person)

      expect(Capybara.string(response.body))
        .to have_css('input[name="person[icon]"][accept="image/png,image/jpeg,image/webp"]')
    end

    it "creates a person with roles and groups" do
      group = create(:group, name: "よく遊ぶ人たち")

      post manage_people_path, params: {
        person: { display_name: "新入り", x_account: "newbie", roles: [ "gm" ], group_ids: [ group.id ] }
      }

      person = Person.find_by(display_name: "新入り")
      expect(response).to redirect_to(person_path(person))
      expect(person.roles).to eq([ "gm" ])
      expect(person).to be_player
      expect(person.groups).to eq([ group ])
    end

    it "carries no explanation under the title" do
      get manage_people_path

      expect(response.body).not_to include("Person は管理者が作ります")
    end

    it "links a Google account to a person" do
      user = create(:user, person: nil, email: "someone@example.com")
      person = create(:person, display_name: "だれか")

      patch manage_user_path(user), params: { user: { person_id: person.id } }

      expect(response).to redirect_to(manage_user_path(user))
      expect(user.reload.person).to eq(person)
    end

    it "unlinks a Google account" do
      person = create(:person)
      user = create(:user, person: person)

      patch manage_user_path(user), params: { user: { person_id: "" } }

      expect(user.reload.person).to be_nil
    end

    it "links people, groups and accounts to both detail and edit screens" do
      person = create(:person)
      group = create(:group)
      user = create(:user, person: nil)

      get manage_people_path
      expect(response.body).to include(person_path(person), edit_manage_person_path(person))

      get manage_groups_path
      expect(response.body).to include(manage_group_path(group), edit_manage_group_path(group))

      get manage_users_path
      expect(response.body).to include(manage_user_path(user), edit_manage_user_path(user))
    end

    it "renders group detail and edit screens with reciprocal links" do
      group = create(:group, people: [ create(:person, display_name: "メンバー") ])

      get manage_group_path(group)
      expect(response.body).to include("メンバー", edit_manage_group_path(group))

      get edit_manage_group_path(group)
      expect(response.body).to include("詳細に戻る", manage_group_path(group))
    end

    it "renders account detail and edit screens with reciprocal links" do
      user = create(:user, person: create(:person, display_name: "紐づけ先"))

      get manage_user_path(user)
      expect(response.body).to include("紐づけ先", edit_manage_user_path(user))

      get edit_manage_user_path(user)
      expect(response.body).to include("詳細に戻る", manage_user_path(user))
    end

    it "refuses to link one person to two accounts" do
      person = create(:person)
      create(:user, person: person)
      other = create(:user, person: nil)

      patch manage_user_path(other), params: { user: { person_id: person.id } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(other.reload.person).to be_nil
    end
  end

  describe "the account linking screen" do
    it "answers 404 to a GM, who must not be able to rebind accounts" do
      sign_in_as create(:person, roles: %w[gm])

      get manage_users_path

      expect(response).to have_http_status(:not_found)
    end

    it "refuses a GM's attempt to link an account" do
      sign_in_as create(:person, roles: %w[gm])
      user = create(:user, person: nil)
      target = create(:person, roles: %w[admin])

      patch manage_user_path(user), params: { user: { person_id: target.id } }

      expect(response).to have_http_status(:not_found)
      expect(user.reload.person).to be_nil
    end

    it "hides account detail and edit screens from a GM" do
      sign_in_as create(:person, roles: %w[gm])
      user = create(:user, person: nil)

      [ manage_user_path(user), edit_manage_user_path(user) ].each do |path|
        get path
        expect(response).to have_http_status(:not_found)
      end
    end

    it "hides group detail and edit screens from a GM" do
      sign_in_as create(:person, roles: %w[gm])
      group = create(:group)

      [ manage_group_path(group), edit_manage_group_path(group) ].each do |path|
        get path
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "keeping an administrator" do
    it "refuses to remove the last admin role" do
      admin = create(:person, roles: %w[admin])
      sign_in_as admin

      patch manage_person_path(admin), params: { person: { display_name: admin.display_name, roles: [ "gm" ] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(admin.reload).to be_admin
    end

    it "allows it once another admin exists" do
      admin = create(:person, roles: %w[admin])
      create(:person, roles: %w[admin])
      sign_in_as admin

      patch manage_person_path(admin), params: { person: { display_name: admin.display_name, roles: [ "gm" ] } }

      expect(admin.reload).not_to be_admin
    end
  end

  describe "linking effects" do
    it "opens the signed-in area once the account is linked" do
      admin = create(:person, roles: %w[admin])
      create(:user, person: admin)
      user = create(:user, person: nil)

      sign_in_as user
      get manage_scenarios_path
      expect(response).to have_http_status(:not_found)

      user.update!(person: create(:person, roles: %w[gm]))

      get manage_scenarios_path
      expect(response).to have_http_status(:ok)
    end
  end
end
