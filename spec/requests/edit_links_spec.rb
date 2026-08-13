require "rails_helper"

# 編集リンクは編集画面と同じ判断で出す。出る相手と出ない相手を画面ごとに固定する。
RSpec.describe "Edit links on detail screens" do
  describe "GET /scenarios/:id" do
    let(:scenario) { create(:scenario) }
    let(:edit_path) { edit_scenario_path(scenario) }

    it "is absent for a visitor who has not signed in" do
      get scenario_path(scenario)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(edit_path)
    end

    it "is absent for an account that is not linked to a person" do
      sign_in_as create(:user, person: nil)

      get scenario_path(scenario)

      expect(response.body).not_to include(edit_path)
    end

    it "is absent for a member who has no role" do
      sign_in_as create(:person)

      get scenario_path(scenario)

      expect(response.body).not_to include(edit_path)
    end

    it "is present for a GM" do
      sign_in_as create(:person, roles: %w[gm])

      get scenario_path(scenario)

      expect(response.body).to include(edit_path)
    end

    it "is present for an admin" do
      sign_in_as create(:person, roles: %w[admin])

      get scenario_path(scenario)

      expect(response.body).to include(edit_path)
    end
  end

  describe "GET /play_sessions/:id" do
    let(:group) { create(:group) }
    let(:play_session) { create(:play_session) }
    let(:edit_path) { edit_play_session_path(play_session) }

    before do
      play_session.participations.create!(person: create(:person, groups: [ group ]), role: :gm)
    end

    it "is absent for a member who may read the session but not edit it" do
      sign_in_as create(:person, groups: [ group ])

      get play_session_path(play_session)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(edit_path)
    end

    it "is present for a GM who may read the session" do
      sign_in_as create(:person, roles: %w[gm], groups: [ group ])

      get play_session_path(play_session)

      expect(response.body).to include(edit_path)
    end

    it "is present for an admin, who may read every session" do
      sign_in_as create(:person, roles: %w[admin])

      get play_session_path(play_session)

      expect(response.body).to include(edit_path)
    end

    it "lets a GM open the detail for a session they can edit" do
      sign_in_as create(:person, roles: %w[gm])

      get play_session_path(play_session)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(edit_path)
    end
  end

  describe "GET /people/:id" do
    let(:person) { create(:person) }
    let(:edit_path) { edit_person_path(person) }

    it "is absent for another member" do
      sign_in_as create(:person)

      get person_path(person)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(edit_path)
    end

    # GM はシナリオとセッションを編集するが、他人のプロフィールには触れない。
    it "is absent for a GM looking at someone else" do
      sign_in_as create(:person, roles: %w[gm])

      get person_path(person)

      expect(response.body).not_to include(edit_path)
    end

    it "is present for the person themselves" do
      sign_in_as person

      get person_path(person)

      expect(response.body).to include(edit_path)
    end

    it "is present for an admin" do
      sign_in_as create(:person, roles: %w[admin])

      get person_path(person)

      expect(response.body).to include(edit_path)
    end
  end
end
