require "rails_helper"

RSpec.describe "PlaySessions" do
  let(:group) { create(:group) }
  let(:participant) { create(:person, display_name: "参加した人", groups: [ group ]) }
  let(:scenario) do
    create(:scenario, title: "見本シナリオ",
      game_systems: [ create(:game_system, game_master_label: "KP") ])
  end
  let(:session) do
    create(:play_session, scenario:).tap do |play_session|
      create(:session_schedule, play_session:, scheduled_on: Date.new(2026, 5, 1))
    end
  end

  before do
    session.participations.create!(person: participant, role: :gm)
  end

  describe "GET /play_sessions" do
    it "is closed to a visitor who has not signed in" do
      get play_sessions_path

      expect(response).to have_http_status(:not_found)
    end

    it "is closed to an account that is not linked to a person" do
      sign_in_as create(:user, person: nil)

      get play_sessions_path

      expect(response).to have_http_status(:not_found)
    end

    it "shows nothing to someone who shares no group with any participant" do
      sign_in_as create(:person)

      get play_sessions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("見本シナリオ")
    end

    it "shows every editable session to a GM on the shared list" do
      sign_in_as create(:person, roles: %w[gm])

      get play_sessions_path

      expect(response.body).to include("見本シナリオ")
      expect(response.body[%r{<h1.*?</h1>}m]).to include("（全1件）")
    end

    it "shows the session to someone in the same group" do
      sign_in_as create(:person, groups: [ group ])

      get play_sessions_path

      expect(response.body).to include("見本シナリオ", "KP: 参加した人")
    end

    # 件数は見える範囲の数。全体の数を出すと、見えない回があることを教えてしまう。
    it "counts only the sessions the viewer may see" do
      hidden = create(:play_session, scenario: create(:scenario, title: "見えない回"))
      hidden.participations.create!(person: create(:person), role: :gm)
      sign_in_as create(:person, groups: [ group ])

      get play_sessions_path

      expect(response.body[%r{<h1.*?</h1>}m]).to include("（全1件）")
    end

    it "counts nothing for someone who shares no group" do
      sign_in_as create(:person)

      get play_sessions_path

      expect(response.body[%r{<h1.*?</h1>}m]).to include("（全0件）")
    end

    it "carries no explanation under the title" do
      sign_in_as create(:person, groups: [ group ])

      get play_sessions_path

      expect(response.body).not_to include("同じグループの人が参加した回だけが並びます")
    end

    # Scope は EXISTS を 2 本抱えるため、件数のために引き直すと素の一覧が倍のコストになる。
    it "evaluates the scope once, not again for the count" do
      sign_in_as create(:person, groups: [ group ])

      sqls = queries_against("play_sessions") { get play_sessions_path }

      expect(sqls.size).to eq(1)
    end
  end

  describe "GET /play_sessions/:id" do
    it "answers 404 to someone outside the scope, without confirming it exists" do
      sign_in_as create(:person)

      get play_session_path(session)

      expect(response).to have_http_status(:not_found)
    end

    it "shows the participants, their roles and their character sheets" do
      session.participations.create!(
        person: create(:person, display_name: "遊んだ人"),
        role: :player,
        character_name: "探索者A",
        character_sheet_url: "https://charasheet.example/1234"
      )
      create(:recording_link, session_schedule: session.session_schedules.first, url: "https://youtu.be/abc")
      sign_in_as create(:person, groups: [ group ])

      get play_session_path(session)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("参加した人", "遊んだ人", "探索者A")
      expect(response.body).to include("https://charasheet.example/1234", "https://youtu.be/abc")
      expect(Capybara.string(response.body)).to have_link(
        "https://charasheet.example/1234",
        href: "https://charasheet.example/1234",
        target: "_blank"
      )
      expect(response.body).to include("KP")
    end

    it "uses the system's label for a supporting game master" do
      session.participations.create!(person: create(:person), role: :sub_gm)
      sign_in_as create(:person, groups: [ group ])

      get play_session_path(session)

      expect(response.body).to include("サブKP")
      expect(response.body).not_to include("サブキーパー")
    end

    it "embeds a YouTube recording" do
      create(:recording_link, session_schedule: session.session_schedules.first,
        url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      sign_in_as create(:person, groups: [ group ])

      get play_session_path(session)

      page = Capybara.string(response.body)
      expect(page).to have_css(
        'iframe[title="録画"][src="https://www.youtube.com/embed/dQw4w9WgXcQ"]'
      )
      expect(page).to have_no_css('[data-controller="video-disclosure"] iframe')
      expect(page).to have_no_link(href: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      expect(page).to have_no_text("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    end

    it "shows every recording under its schedule" do
      second_schedule = create(:session_schedule, play_session: session,
        scheduled_on: Date.new(2026, 5, 3))
      create(:recording_link, session_schedule: session.session_schedules.first,
        url: "https://videos.example/first")
      create(:recording_link, session_schedule: second_schedule,
        url: "https://videos.example/second")
      sign_in_as create(:person, groups: [ group ])

      get play_session_path(session)

      expect(response.body).to include("https://videos.example/first", "https://videos.example/second")
      expect(response.body).not_to include(">状態<")
      page = Capybara.string(response.body)
      schedule_sections = page.all("[data-session-schedule]")
      expect(schedule_sections.first).to have_text("2026年5月1日（金） 20:00")
        .and have_text("https://videos.example/first")
        .and have_no_text("https://videos.example/second")
      expect(schedule_sections[1]).to have_text("2026年5月3日（日） 20:00")
        .and have_text("https://videos.example/second")
    end

    it "shows the start time without the placeholder date a time column carries" do
      sign_in_as create(:person, groups: [ group ])

      get play_session_path(session)

      expect(response.body).to include("2026年5月1日（金） 20:00")
      expect(response.body).not_to include("2000-01-01")
    end

    it "shows the note to a viewer who is allowed to see the session" do
      session.update!(note: "覚え書きの見本 https://example.com/note")
      sign_in_as create(:person, groups: [ group ])

      get play_session_path(session)

      expect(response.body).to include("覚え書きの見本")
      expect(Capybara.string(response.body)).to have_link(
        "https://example.com/note", href: "https://example.com/note", target: "_blank"
      )
    end

    it "shows the Cocofolia URL to a participant" do
      session.update!(cocofolia_url: "https://ccfolia.com/rooms/participant-only")
      sign_in_as participant

      get play_session_path(session)

      expect(response.body).to include("ココフォリア", "https://ccfolia.com/rooms/participant-only")
    end

    it "keeps the Cocofolia URL out of the response for a group peer who is not a participant" do
      session.update!(cocofolia_url: "https://ccfolia.com/rooms/participant-only")
      sign_in_as create(:person, groups: [ group ])

      get play_session_path(session)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("ココフォリア", "https://ccfolia.com/rooms/participant-only")
    end

    it "keeps the Cocofolia URL out of the response for an admin who is not a participant" do
      session.update!(cocofolia_url: "https://ccfolia.com/rooms/participant-only")
      sign_in_as create(:person, roles: %w[admin])

      get play_session_path(session)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("ココフォリア", "https://ccfolia.com/rooms/participant-only")
    end

    it "links back to the scenario" do
      sign_in_as create(:person, groups: [ group ])

      get play_session_path(session)

      expect(response.body).to include(scenario_path(scenario))
    end
  end

  describe "the history on a scenario page" do
    it "is absent for a visitor who has not signed in" do
      get scenario_path(scenario)

      expect(response.body).not_to include("参加した人")
    end

    it "is absent for someone outside the scope" do
      sign_in_as create(:person)

      get scenario_path(scenario)

      expect(response.body).not_to include("参加した人")
    end

    it "appears for someone in the same group" do
      sign_in_as create(:person, groups: [ group ])

      get scenario_path(scenario)

      expect(response.body).to include("セッション履歴")
      expect(response.body).to include(play_session_path(session))
    end
  end
end
