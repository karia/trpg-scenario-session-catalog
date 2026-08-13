require "rails_helper"

# GameSystem と Author は Manage::MastersController の振る舞いを共有する。
RSpec.describe "Manage masters" do
  let(:headers) { {} }

  shared_examples "a master resource" do |factory:, index_path:, member_path:, edit_path:|
    let(:record) { create(factory, name: "既存") }

    it "answers 404 to an anonymous visitor" do
      get public_send(index_path)

      expect(response).to have_http_status(:not_found)
    end

    it "lists the records" do
      sign_in_as create(:person, roles: %w[gm])
      record

      get public_send(index_path), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("既存")
    end

    it "creates a record and opens its detail" do
      sign_in_as create(:person, roles: %w[gm])
      post public_send(index_path), headers: headers, params: { factory => { name: "新規" } }

      created = factory.to_s.camelize.constantize.find_by!(name: "新規")
      expect(response).to redirect_to(public_send(member_path, created))
    end

    it "re-renders on a blank name" do
      sign_in_as create(:person, roles: %w[gm])
      post public_send(index_path), headers: headers, params: { factory => { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "renders the edit form on the member path" do
      sign_in_as create(:person, roles: %w[gm])
      get public_send(edit_path, record), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(public_send(member_path, record), "詳細に戻る")
    end

    it "aligns name fields and chooses the display name from a select" do
      record.aliases.create!(name: "別名")
      sign_in_as create(:person, roles: %w[gm])

      get public_send(edit_path, record), headers: headers

      page = Capybara.string(response.body)
      expect(page).to have_css("input.w-full", count: 2)
      expect(page).to have_css("input[type=checkbox][disabled]", count: 2)
      expect(page).to have_no_css("input[type=radio]")
      expect(page).to have_select("#{factory}[display_alias_key]", options: [ "既存（現在の表示名）", "別名" ])
    end

    it "renders a detail with links to its edit screen and list" do
      sign_in_as create(:person, roles: %w[gm])

      get public_send(member_path, record), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(public_send(edit_path, record), public_send(index_path))
    end

    it "links each list item to both detail and edit" do
      sign_in_as create(:person, roles: %w[gm])
      record

      get public_send(index_path), headers: headers

      expect(response.body).to include(public_send(member_path, record), public_send(edit_path, record))
    end

    it "updates through the member path rather than the collection" do
      sign_in_as create(:person, roles: %w[gm])
      patch public_send(member_path, record), headers: headers, params: { factory => { name: "改名" } }

      expect(response).to redirect_to(public_send(member_path, record))
      expect(record.reload.name).to eq("改名")
    end

    it "adds aliases and promotes a visible one to the display name" do
      sign_in_as create(:person, roles: %w[gm])
      patch public_send(member_path, record), params: {
        factory => { aliases_attributes: [ { name: "別名", visible: "1" } ] }
      }
      selected = record.reload.aliases.sole

      patch public_send(member_path, record), params: {
        factory => { name: record.name, display_alias_key: selected.id }
      }

      expect(record.reload.name).to eq("別名")
      expect(selected.reload.name).to eq("既存")
    end

    it "adds an alias and selects it as the display name in one update" do
      sign_in_as create(:person, roles: %w[gm])

      patch public_send(member_path, record), params: {
        factory => {
          name: record.name,
          display_alias_key: "new-name",
          aliases_attributes: [ { name: "新しい表示名", visible: "1", selection_key: "new-name" } ]
        }
      }

      expect(record.reload.name).to eq("新しい表示名")
      expect(record.aliases.sole.name).to eq("既存")
    end

    it "destroys a record" do
      sign_in_as create(:person, roles: %w[gm])
      record

      expect { delete public_send(member_path, record), headers: headers }
        .to change(factory.to_s.camelize.constantize, :count).by(-1)
    end
  end

  describe "game systems" do
    it_behaves_like "a master resource",
      factory: :game_system,
      index_path: :manage_game_systems_path,
      member_path: :manage_game_system_path,
      edit_path: :edit_manage_game_system_path

    it "updates the game master label" do
      system = create(:game_system, name: "エモクロアTRPG")
      sign_in_as create(:person, roles: %w[gm])

      patch manage_game_system_path(system), params: {
        game_system: { name: system.name, game_master_label: "DL" }
      }

      expect(system.reload.game_master_label).to eq("DL")
    end
  end

  describe "authors" do
    it_behaves_like "a master resource",
      factory: :author,
      index_path: :manage_authors_path,
      member_path: :manage_author_path,
      edit_path: :edit_manage_author_path
  end
end
