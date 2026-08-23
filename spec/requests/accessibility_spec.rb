require "rails_helper"

RSpec.describe "Accessibility" do
  it "provides named landmarks and a skip link on every page" do
    get root_path

    page = Capybara.string(response.body)
    expect(page).to have_link("本文へ移動", href: "#main-content")
    expect(page).to have_css('nav[aria-label="主要"]')
    expect(page).to have_css('main#main-content[tabindex="-1"]')
    expect(page).to have_css("body.bg-ui-background.text-ui-text")
    expect(page).to have_css('main[data-ui-theme="legacy"].bg-paper.text-ink')
  end

  it "announces alert flashes assertively" do
    get auth_failure_path

    follow_redirect!
    expect(Capybara.string(response.body)).to have_css(
      '[role="alert"].border-ui-error.text-ui-error', text: "ログインできませんでした"
    )
  end

  it "makes the scenario management table reflow and names every column" do
    sign_in_as create(:person, roles: %w[gm])
    create(:scenario)

    get scenario_order_index_path

    page = Capybara.string(response.body)
    expect(page).to have_css('[role="region"][aria-label="シナリオの並び順と操作"][tabindex="0"] table')
    expect(page).to have_css('th[scope="col"]', text: "操作")
  end

  it "keeps labels visible for repeated session fields" do
    sign_in_as create(:person, roles: %w[gm])
    play_session = create(:play_session)
    create(:participation, play_session:)
    schedule = create(:session_schedule, play_session:)
    create(:recording_link, session_schedule: schedule)

    get edit_play_session_path(play_session)

    page = Capybara.string(response.body)
    expect(page).to have_css("fieldset legend", text: "参加者")
    expect(page).to have_css("label:not(.sr-only)", text: "キャラクター名")
    expect(page).to have_css("label:not(.sr-only)", text: "録画URL")
  end

  it "links an error summary to the invalid field and describes that field" do
    sign_in_as create(:person, roles: %w[gm])

    post scenarios_path, params: { scenario: { title: "" } }

    page = Capybara.string(response.body)
    expect(page).to have_css('[data-controller="error-summary"][tabindex="-1"] a[data-error-attribute="title"]')
    expect(page).to have_css('#scenario_title[aria-invalid="true"][aria-describedby="scenario_title_error"]')
    expect(page).to have_css("#scenario_title_error", visible: :all)
  end

  it "exposes the rendered nested field ID to the error summary controller" do
    sign_in_as create(:person, roles: %w[gm])

    post scenarios_path,
      params: { scenario: { title: "シナリオ", purchase_links_attributes: [ { label: "購入", url: "invalid" } ] } }

    page = Capybara.string(response.body)
    expect(page).to have_css('a[data-error-attribute="purchase_links.url"]')
    expect(page).to have_css('[id$="_url_error"][data-error-attribute="url"]', visible: :all)
  end

  it "renders form-wide errors without a dead field link" do
    record = build(:play_session)
    record.errors.add(:base, "同じ人を複数の行に指定できません")

    summary = Capybara.string(ApplicationController.helpers.accessible_error_summary(record))
    expect(summary).to have_text("同じ人を複数の行に指定できません")
    expect(summary).to have_no_link
  end
end
