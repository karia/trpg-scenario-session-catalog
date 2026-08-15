require "rails_helper"

# 共有ナビゲーションへ統合した画面群の契約を、個別画面の実装から独立して固定する。
RSpec.describe "Signed-in interface contract" do
  let(:admin) { create(:person, roles: %w[admin]) }

  before { sign_in_as admin }

  describe "resource names" do
    let(:resources) do
      [
        [ Scenario, scenarios_path, new_scenario_path ],
        [ PlaySession, play_sessions_path, new_play_session_path ],
        [ Person, people_path, new_person_path ],
        [ Author, authors_path, new_author_path ],
        [ GameSystem, game_systems_path, new_game_system_path ]
      ]
    end

    it "derives every shared list and creation heading from the model translation" do
      original_locales = I18n.available_locales
      I18n.available_locales = original_locales | [ :en ]

      I18n.with_locale(:en) do
        resources.each do |model, index_path, new_path|
          get index_path
          expect(Capybara.string(response.body)).to have_css("h1", text: model.model_name.human)

          get new_path
          expect(Capybara.string(response.body)).to have_css(
            "h1", text: "#{model.model_name.human}の新規登録"
          )
        end

        get root_path
        menu = Capybara.string(response.body).find("nav#account-menu", visible: :all)
        resources.each do |model, index_path, _new_path|
          expect(menu).to have_link(model.model_name.human, href: index_path, visible: :all)
        end
        [
          [ Group, manage_groups_path ],
          [ User, manage_users_path ],
          [ SiteSetting, manage_site_setting_path ]
        ].each do |model, path|
          expect(menu).to have_link(model.model_name.human, href: path, visible: :all)
        end
      end
    ensure
      I18n.available_locales = original_locales
    end

    it "renders exactly one way back from every creation form" do
      resources.each do |_model, index_path, new_path|
        get new_path

        expect(response).to have_http_status(:ok)
        expect(Capybara.string(response.body)).to have_link("一覧に戻る", href: index_path, count: 1)
      end
    end
  end

  describe "the unified administration area" do
    let(:destinations) do
      [
        scenarios_path,
        play_sessions_path,
        people_path,
        authors_path,
        game_systems_path,
        manage_groups_path,
        manage_users_path,
        manage_site_setting_path
      ]
    end

    it "never restores the obsolete second management navigation" do
      destinations.each do |path|
        get path
        expect(Capybara.string(response.body)).to have_no_css('nav[aria-label="管理"]'), path
      end
    end

    it "offers one edit destination containing profile and administration fields" do
      person = create(:person)
      person.aliases.create!(name: "別名")
      group = create(:group)

      get person_path(person)
      expect(Capybara.string(response.body)).to have_link("編集", href: edit_person_path(person), count: 1)

      get edit_person_path(person)
      form = Capybara.string(response.body)
      expect(form).to have_field("X のアカウント名（@ は不要）")
      expect(form).to have_css('input[name="person[aliases_attributes][0][name]"]')
      expect(form).to have_css('input[name="person[roles][]"]')
      expect(form).to have_field(group.name)
    end
  end
end
