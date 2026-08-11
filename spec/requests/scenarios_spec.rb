require "rails_helper"

RSpec.describe "Scenarios" do
  describe "GET /" do
    it "is readable without signing in" do
      create(:scenario, title: "カタシロ")

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("カタシロ")
    end
  end

  describe "GET /scenarios/:id" do
    let(:scenario) do
      create(
        :scenario,
        title: "ロールシャッハシンドローム",
        synopsis: "あらすじ本文",
        preparation_note: "ネタバレを含む準備情報",
        recommendation_note: "GM が推す一点",
        player_count_min: 2,
        player_count_max: 4,
        duration_min_hours: 3,
        duration_max_hours: 5,
        character_restriction: "継続キャラクター限定",
        character_sheet_deadline: :two_days_before,
        character_sheet_deadline_note: "正午までに提出",
        game_systems: [ create(:game_system, name: "エモクロアTRPG") ],
        authors: [ create(:author, name: "ディズム") ]
      )
    end

    it "is readable without signing in" do
      get scenario_path(scenario)

      expect(response).to have_http_status(:ok)
    end

    it "shows the public fields" do
      scenario.purchase_links.create!(label: "BOOTH", url: "https://booth.pm/ja/items/1")
      scenario.stream_links.create!(label: "配信", url: "https://youtu.be/abc")

      get scenario_path(scenario)

      expect(response.body).to include("ロールシャッハシンドローム", "あらすじ本文", "エモクロアTRPG", "ディズム")
      expect(response.body).to include("https://booth.pm/ja/items/1", "https://youtu.be/abc")
      expect(response.body).to include("2人〜4人", "3時間〜5時間")
      expect(response.body).to include("この情報はGMが独自判断で記載しており、シナリオ公式の案内と異なる場合があります")
    end

    it "uses the imported BOOTH image when no jacket is attached" do
      scenario.booth_image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "booth-detail.png", content_type: "image/png"
      )

      get scenario_path(scenario)

      expect(response.body).to include("booth-detail.png")
    end

    it "fits the whole jacket inside its frame" do
      scenario.jacket.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "jacket.png", content_type: "image/png"
      )

      get scenario_path(scenario)

      expect(Capybara.string(response.body)).to have_css("img.object-contain")
      expect(Capybara.string(response.body)).not_to have_css("img.object-cover")
    end

    it "keeps the GM supplementary information out of the response for a visitor" do
      get scenario_path(scenario)

      expect(response.body).not_to include("GMからの補足情報", "継続キャラクター限定", "正午までに提出")
      expect(response.body).not_to include("セッション前々日")
    end

    it "keeps the GM supplementary information out of the response for a user with no person" do
      sign_in_as(create(:user))

      get scenario_path(scenario)

      expect(response.body).not_to include("GMからの補足情報", "継続キャラクター限定", "正午までに提出")
      expect(response.body).not_to include("セッション前々日")
    end

    it "shows the GM supplementary information below the recommendation to a signed-in member" do
      sign_in_as(create(:person))

      get scenario_path(scenario)

      expect(response.body).to include(
        "GMからの補足情報", "参加可能キャラの制限", "継続キャラクター限定",
        "キャラシ提出期限", "セッション前々日", "キャラシ提出期限の補足", "正午までに提出"
      )
      expect(response.body.index("GMからのオススメポイント")).to be < response.body.index("GMからの補足情報")
    end

    it "embeds YouTube stream links and leaves other stream links clickable" do
      scenario.stream_links.create!(label: "YouTube配信", url: "https://youtu.be/dQw4w9WgXcQ")
      scenario.stream_links.create!(label: "別サイトの配信", url: "https://example.com/stream")

      get scenario_path(scenario)

      page = Capybara.string(response.body)
      hidden_embed = '[data-controller="video-disclosure"] [data-video-disclosure-target="content"][hidden] ' \
        'iframe[title="YouTube配信"][src="https://www.youtube.com/embed/dQw4w9WgXcQ"]'
      expect(page).to have_css(hidden_embed, visible: :all)
      expect(page).to have_button("おすすめ配信を開く")
      expect(page).to have_button("おすすめ配信を閉じる", visible: :all)
      expect(page).to have_css('[data-video-disclosure-target="content"].bg-surface', visible: :all)
      expect(page).to have_css('[data-controller="video-disclosure"]' \
        '[data-action*="turbo:before-cache@document->video-disclosure#reset"]')
      expect(page).to have_css('[data-video-disclosure-target="closeButton"]', visible: :all)
      expect(page).to have_no_link("YouTube配信", href: "https://youtu.be/dQw4w9WgXcQ", visible: :all)
      expect(response.body).not_to include("https://youtu.be/dQw4w9WgXcQ")
      expect(page).to have_link("別サイトの配信", href: "https://example.com/stream", visible: :all)
      expect(response.body).to include("https://example.com/stream")
    end

    it "leaves a YouTube URL with a malformed query string clickable" do
      url = "https://youtube.com/watch?v=dQw4w9WgXcQ&x=%"
      scenario.stream_links.create!(label: "配信", url:)

      get scenario_path(scenario)

      page = Capybara.string(response.body)
      expect(response).to have_http_status(:ok)
      expect(page).to have_link("配信", href: url, visible: :all)
      expect(page).to have_no_css("iframe")
    end

    it "keeps the preparation note out of the response entirely" do
      get scenario_path(scenario)

      expect(response.body).not_to include("ネタバレを含む準備情報")
    end

    it "keeps the recommendation note out of the response for a visitor" do
      get scenario_path(scenario)

      expect(response.body).not_to include("GM が推す一点")
      expect(response.body).not_to include("GMからのオススメポイント")
    end

    it "keeps the recommendation note out of the response for a user with no person" do
      sign_in_as(create(:user))

      get scenario_path(scenario)

      expect(response.body).not_to include("GM が推す一点")
      expect(response.body).not_to include("GMからのオススメポイント")
    end

    it "shows the recommendation note to a signed-in member" do
      sign_in_as(create(:person))

      get scenario_path(scenario)

      expect(response.body).to include("GMからのオススメポイント", "GM が推す一点")
    end

    it "puts the scenario name in the page title" do
      get scenario_path(scenario)

      expect(response.body).to include("<title>ロールシャッハシンドローム | TRPGカタログ</title>")
    end

    it "gives the JSON-LD block a nonce that matches the policy header" do
      get scenario_path(scenario)

      nonce = response.headers["Content-Security-Policy"][/'nonce-([^']+)'/, 1]
      expect(nonce).to be_present
      expect(response.body).to include(%(nonce="#{nonce}"))
    end

    it "escapes a title that would otherwise break out of the JSON-LD block" do
      scenario.update!(title: %(危険</script><script>alert(1)</script>))

      get scenario_path(scenario)

      expect(response.body).not_to include("</script><script>alert(1)")
    end

    it "renders a purchase link that has a label but no URL" do
      scenario.purchase_links.create!(label: "書籍購入者限定特典", url: nil)

      get scenario_path(scenario)

      expect(response.body).to include("書籍購入者限定特典")
    end
  end
end
