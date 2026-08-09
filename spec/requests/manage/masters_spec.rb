require "rails_helper"

# GameSystem と Author は Manage::MastersController の振る舞いを共有する。
RSpec.describe "Manage masters" do
  let(:credentials) { ActionController::HttpAuthentication::Basic.encode_credentials("editor", "secret") }
  let(:headers) { { "HTTP_AUTHORIZATION" => credentials } }

  around do |example|
    ClimateControl.modify(MANAGE_USERNAME: "editor", MANAGE_PASSWORD: "secret") { example.run }
  end

  shared_examples "a master resource" do |factory:, index_path:, member_path:, edit_path:|
    let(:record) { create(factory, name: "既存") }

    it "answers 401 without credentials" do
      get public_send(index_path)

      expect(response).to have_http_status(:unauthorized)
    end

    it "lists the records" do
      record

      get public_send(index_path), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("既存")
    end

    it "creates a record" do
      post public_send(index_path), headers: headers, params: { factory => { name: "新規" } }

      expect(response).to redirect_to(public_send(index_path))
      expect(factory.to_s.camelize.constantize.find_by(name: "新規")).to be_present
    end

    it "re-renders on a blank name" do
      post public_send(index_path), headers: headers, params: { factory => { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "renders the edit form on the member path" do
      get public_send(edit_path, record), headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "updates through the member path rather than the collection" do
      patch public_send(member_path, record), headers: headers, params: { factory => { name: "改名" } }

      expect(response).to redirect_to(public_send(index_path))
      expect(record.reload.name).to eq("改名")
    end

    it "destroys a record" do
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
  end

  describe "authors" do
    it_behaves_like "a master resource",
      factory: :author,
      index_path: :manage_authors_path,
      member_path: :manage_author_path,
      edit_path: :edit_manage_author_path
  end
end
