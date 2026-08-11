require "rails_helper"

RSpec.describe "Manage::Scenarios" do
  describe "without a signed-in editor" do
    it "answers 404 to an anonymous visitor" do
      get manage_scenarios_path

      expect(response).to have_http_status(:not_found)
    end

    it "answers 404 to a user who is not linked to a person" do
      sign_in_as create(:user, person: nil)

      get manage_scenarios_path

      expect(response).to have_http_status(:not_found)
    end

    it "answers 404 to a person with no role" do
      sign_in_as create(:person)

      get manage_scenarios_path

      expect(response).to have_http_status(:not_found)
    end

    it "does not create a scenario for an anonymous visitor" do
      post manage_scenarios_path, params: { scenario: { title: "侵入" } }

      expect(response).to have_http_status(:not_found)
      expect(Scenario.count).to eq(0)
    end

    # 並び順は公開側の見た目を決める。編集エリアと同じ壁の内側に置く。
    it "does not rearrange the list for an anonymous visitor" do
      first = create(:scenario)
      second = create(:scenario)

      patch reorder_manage_scenarios_path, params: { scenario_ids: [ second.id, first.id ] }

      expect(response).to have_http_status(:not_found)
      expect(first.reload.position).to be < second.reload.position
    end

    it "does not rearrange the list for a user who is not linked to a person" do
      first = create(:scenario)
      second = create(:scenario)
      sign_in_as create(:user, person: nil)

      patch reorder_manage_scenarios_path, params: { scenario_ids: [ second.id, first.id ] }

      expect(response).to have_http_status(:not_found)
      expect(first.reload.position).to be < second.reload.position
    end

    it "does not rearrange the list for a person with no role" do
      first = create(:scenario)
      second = create(:scenario)
      sign_in_as create(:person)

      patch reorder_manage_scenarios_path, params: { scenario_ids: [ second.id, first.id ] }

      expect(response).to have_http_status(:not_found)
      expect(first.reload.position).to be < second.reload.position
    end

    it "does not move a single row for anyone outside the editors" do
      first = create(:scenario)
      second = create(:scenario)

      patch move_manage_scenario_path(second, direction: "up")

      expect(response).to have_http_status(:not_found)
      expect(first.reload.position).to be < second.reload.position
    end

    it "does not refresh a BOOTH image for anyone outside the editors" do
      scenario = create(:scenario)

      post refresh_booth_image_manage_scenario_path(scenario)

      expect(response).to have_http_status(:not_found)
    end

    it "does not delete a jacket for anyone outside the editors" do
      scenario = create(:scenario)
      scenario.jacket.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "jacket.png", content_type: "image/png"
      )

      delete jacket_manage_scenario_path(scenario)

      expect(response).to have_http_status(:not_found)
      expect(scenario.reload.jacket).to be_attached
    end
  end

  describe "as a GM" do
    before { sign_in_as create(:person, roles: %w[gm]) }

    def authorized_get(path)
      get path
    end

    it "lists the scenarios" do
      create(:scenario, title: "カタシロ")

      authorized_get manage_scenarios_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("カタシロ")
    end

    describe "rearranging the list" do
      it "lists the scenarios in the order the GM arranged, not by title" do
        create(:scenario, title: "あ", position: 2)
        create(:scenario, title: "ま", position: 1)

        authorized_get manage_scenarios_path

        expect(response.body.index("ま")).to be < response.body.index("あ")
      end

      it "hands each row to the browser with its identifier" do
        scenario = create(:scenario)

        authorized_get manage_scenarios_path

        expect(Capybara.string(response.body))
          .to have_css(%(tr[draggable="true"][data-sortable-id-param="#{scenario.id}"]))
      end

      it "saves the new order" do
        first = create(:scenario, title: "いち")
        second = create(:scenario, title: "に")
        third = create(:scenario, title: "さん")

        patch reorder_manage_scenarios_path, params: { scenario_ids: [ third.id, first.id, second.id ] }

        expect(response).to have_http_status(:no_content)
        expect(Scenario.gm_ordered.pluck(:title)).to eq([ "さん", "いち", "に" ])
      end

      it "leaves the order alone when nothing is sent" do
        first = create(:scenario)
        second = create(:scenario)

        patch reorder_manage_scenarios_path

        expect(response).to have_http_status(:no_content)
        expect(Scenario.gm_ordered).to eq([ first, second ])
      end

      it "does not fall over when the identifiers arrive as a hash" do
        first = create(:scenario)
        second = create(:scenario)

        patch reorder_manage_scenarios_path, params: { scenario_ids: { a: second.id } }

        expect(response).to have_http_status(:no_content)
        expect(Scenario.gm_ordered).to eq([ first, second ])
      end

      # ドラッグを使えない相手のための経路。ボタンだけで並べ替えられる。
      it "moves one row up from a plain button" do
        create(:scenario, title: "うえ")
        bottom = create(:scenario, title: "した")

        patch move_manage_scenario_path(bottom, direction: "up")

        expect(response).to redirect_to(manage_scenarios_path)
        expect(Scenario.gm_ordered.pluck(:title)).to eq([ "した", "うえ" ])
      end

      it "offers those buttons on every row" do
        scenario = create(:scenario, title: "カタシロ")

        authorized_get manage_scenarios_path

        expect(Capybara.string(response.body))
          .to have_css(%(form[action="#{move_manage_scenario_path(scenario, direction: 'up')}"] button))
      end
    end

    it "creates a scenario with its systems, authors and links in one submission" do
      system = create(:game_system, name: "エモクロアTRPG")
      author = create(:author, name: "ディズム")

      post manage_scenarios_path,
        params: {
          scenario: {
            title: "変葬",
            game_system_ids: [ system.id ],
            author_ids: [ author.id ],
            player_count_min: 1,
            player_count_max: 1,
            duration_min_hours: 2,
            duration_max_hours: 3,
            recommendation: 4,
            character_sheet_deadline: "one_week_before",
            purchase_links_attributes: [ { label: "BOOTH", url: "https://booth.pm/ja/items/3129552" } ],
            stream_links_attributes: [ { label: "配信", url: "https://youtu.be/xyz" } ]
          }
        }

      scenario = Scenario.sole
      expect(scenario.title).to eq("変葬")
      expect(scenario.game_systems).to eq([ system ])
      expect(scenario.authors).to eq([ author ])
      expect(scenario.purchase_links.map(&:label)).to eq([ "BOOTH" ])
      expect(scenario.stream_links.map(&:url)).to eq([ "https://youtu.be/xyz" ])
    end

    it "re-renders the form when the title is missing" do
      post manage_scenarios_path,
        params: { scenario: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Scenario.count).to eq(0)
    end

    # セッションごと消えると参加記録が失われる。外部キーで止まっていた挙動を保つ。
    it "refuses to delete a scenario that still has sessions" do
      scenario = create(:scenario)
      create(:play_session, scenario: scenario)

      expect { delete manage_scenario_path(scenario) }.not_to change(Scenario, :count)
      expect(PlaySession.count).to eq(1)
    end

    it "deletes a scenario that has no sessions" do
      scenario = create(:scenario)

      expect { delete manage_scenario_path(scenario) }.to change(Scenario, :count).by(-1)
    end

    it "updates a scenario" do
      scenario = create(:scenario, title: "旧題")

      patch manage_scenario_path(scenario), params: { scenario: { title: "新題" } }

      expect(scenario.reload.title).to eq("新題")
    end

    it "offers a manual BOOTH image refresh on the edit screen" do
      scenario = create(:scenario)

      get edit_manage_scenario_path(scenario)

      expect(response.body).to include("BOOTH画像を更新")
    end

    it "offers jacket deletion only when a jacket is attached" do
      scenario = create(:scenario)

      get edit_manage_scenario_path(scenario)
      expect(response.body).not_to include("ジャケット画像を削除")

      scenario.jacket.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "jacket.png", content_type: "image/png"
      )

      get edit_manage_scenario_path(scenario)
      expect(Capybara.string(response.body))
        .to have_css(%(form[action="#{jacket_manage_scenario_path(scenario)}"] button), text: "ジャケット画像を削除")
    end

    it "deletes an uploaded jacket and exposes the BOOTH image fallback" do
      scenario = create(:scenario)
      scenario.jacket.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "jacket.png", content_type: "image/png"
      )
      scenario.booth_image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "booth-fallback.png", content_type: "image/png"
      )

      delete jacket_manage_scenario_path(scenario)

      expect(response).to redirect_to(edit_manage_scenario_path(scenario))
      expect(flash[:notice]).to eq("ジャケット画像を削除しました")
      expect(scenario.reload.jacket).not_to be_attached

      get scenario_path(scenario)
      expect(response.body).to include("booth-fallback.png")
    end

    it "refreshes the BOOTH image and reports success" do
      scenario = create(:scenario)
      result = BoothImageImporter::Result.new(success: true, message: "BOOTH画像を更新しました")
      importer = instance_double(BoothImageImporter, call: result)
      allow(BoothImageImporter).to receive(:new).with(scenario).and_return(importer)

      post refresh_booth_image_manage_scenario_path(scenario)

      expect(importer).to have_received(:call).with(force: true)
      expect(response).to redirect_to(edit_manage_scenario_path(scenario))
      expect(flash[:notice]).to eq("BOOTH画像を更新しました")
    end

    it "reports a manual refresh failure without treating it as success" do
      scenario = create(:scenario)
      result = BoothImageImporter::Result.new(success: false, message: "BOOTH画像を取得できませんでした")
      allow(BoothImageImporter).to receive(:new).and_return(instance_double(BoothImageImporter, call: result))

      post refresh_booth_image_manage_scenario_path(scenario)

      expect(flash[:alert]).to eq("BOOTH画像を取得できませんでした")
    end
  end
end
