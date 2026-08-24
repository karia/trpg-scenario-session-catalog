require "rails_helper"

# 個別の spec は自分の画面しか見ないため、画面をまたいで初めて分かる差異はここで固定する。
module CrossScreenAudit
end

RSpec.describe "Cross-screen audit" do
  CrossScreenAudit::INTERACTIVE = 'a[href], button, input:not([type="hidden"]), select, textarea, summary, [tabindex]:not([tabindex="-1"])'.freeze

  # 共通部品は focus-visible:outline-none と ring を組み合わせるため、outline だけを見ると取りこぼす。
  # 日時入力のカレンダーボタンはブラウザのシャドウDOM側にあり、:focus が host に当たらない。ここは browser が描く。
  CrossScreenAudit::FOCUS_INDICATOR = <<~JS.freeze
    (() => {
      const active = document.activeElement
      if (!active || active === document.body || active === document.documentElement) return null
      const style = getComputedStyle(active)
      const outlined = style.outlineStyle !== "none" && parseFloat(style.outlineWidth) > 0
      const ringed = style.boxShadow !== "none" && style.boxShadow !== "" &&
        style.boxShadow !== "rgba(0, 0, 0, 0) 0px 0px 0px 0px"
      const browserDrawnDateIndicator = active instanceof HTMLInputElement &&
        ["date", "datetime-local", "time"].includes(active.type) && !active.matches(":focus")
      return {
        name: (active.getAttribute("aria-label") || active.textContent || active.value || active.name || active.id || "").trim().slice(0, 60),
        tag: active.tagName.toLowerCase(),
        indicated: browserDrawnDateIndicator || outlined || ringed
      }
    })()
  JS

  # WCAG 2.5.8 は地の文に埋まったリンクを対象から外す。ADR の 44px は自主基準なので同じ免除を置く。
  CrossScreenAudit::SMALL_TARGETS = <<~JS.freeze
    (() => {
      const shown = (el) => {
        const rect = el.getBoundingClientRect()
        const style = getComputedStyle(el)
        return rect.width > 0 && rect.height > 0 && style.visibility !== "hidden"
      }
      const box = (el) => {
        const own = el.getBoundingClientRect()
        const label = el.closest("label")
        if (!label) return { width: own.width, height: own.height }
        const wrapper = label.getBoundingClientRect()
        return { width: Math.max(own.width, wrapper.width), height: Math.max(own.height, wrapper.height) }
      }
      const inRunningText = (el) => {
        if (el.tagName !== "A" || getComputedStyle(el).display !== "inline") return false
        const container = el.closest("p, li, dd, dt, figcaption, blockquote")
        if (!container) return false
        const texts = document.createTreeWalker(container, NodeFilter.SHOW_TEXT)
        while (texts.nextNode()) {
          if (!el.contains(texts.currentNode) && texts.currentNode.textContent.trim() !== "") return true
        }
        return false
      }
      return Array.from(document.querySelectorAll(#{CrossScreenAudit::INTERACTIVE.dump}))
        .filter(shown)
        .filter((el) => !inRunningText(el))
        .filter((el) => { const rect = box(el); return rect.width < 44 || rect.height < 44 })
        .map((el) => {
          const rect = box(el)
          const name = (el.getAttribute("aria-label") || el.textContent || el.value || el.name || el.id || "").trim().slice(0, 40)
          return `${el.tagName.toLowerCase()} ${name} ${Math.round(rect.width)}x${Math.round(rect.height)}`
        })
    })()
  JS

  # 共通部品が付ける形の指紋だけを見る。色は variant ごとに変わるので見ない。
  CrossScreenAudit::SHARED_BUTTON_SHAPE = "inline-flex min-h-11 items-center justify-center gap-2 rounded-ui-control border".freeze
  CrossScreenAudit::ACTION_LABELS = %w[新規登録 詳細 編集 削除].freeze

  CrossScreenAudit::NAMED_CONTROLS = <<~JS.freeze
    Array.from(document.querySelectorAll("a[href], button")).map((el) => ({
      name: (el.textContent || "").trim(),
      tag: el.tagName.toLowerCase(),
      classes: el.className
    }))
  JS

  before do
    skip "Chrome is required for the cross-screen audit" unless ENV["CHROME_BINARY"].present?
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  let(:audit) { build_audit_fixtures }

  it "gives every screen a large enough target for each control" do
    sign_in_as_admin

    offenders = [ 320, 1280 ].flat_map do |width|
      page.current_window.resize_to(width, 900)
      every_screen.flat_map do |path|
        visit path
        page.evaluate_script(CrossScreenAudit::SMALL_TARGETS).map { |control| "#{path} at #{width}px: #{control}" }
      end
    end

    expect(offenders.uniq).to be_empty, "targets under 44px:\n#{offenders.uniq.join("\n")}"
  end

  it "keeps a visible focus indicator on every control the keyboard can reach" do
    sign_in_as_admin
    page.current_window.resize_to(1280, 900)

    unindicated = every_screen.flat_map do |path|
      visit path
      start_from_the_top_of(path)
      walk_with_tab(path).reject { |stop| stop.fetch("indicated") }
        .map { |stop| "#{path}: #{stop['tag']} #{stop['name']}" }
    end

    expect(unindicated.uniq).to be_empty, "controls without a focus indicator:\n#{unindicated.uniq.join("\n")}"
  end

  it "starts every screen at the skip link and moves focus into the main landmark" do
    sign_in_as_admin
    page.current_window.resize_to(1280, 900)

    every_screen.each do |path|
      visit path
      start_from_the_top_of(path)
      press_tab
      expect(page).to have_css('a[href="#main-content"]:focus'), path
      expect(page.evaluate_script("document.activeElement.getBoundingClientRect().top")).to be >= 0, path

      page.driver.browser.action.send_keys(:enter).perform
      expect(page).to have_css("main#main-content:focus"), path
    end
  end

  it "opens and closes the account menu from the keyboard alone" do
    sign_in_as_admin
    page.current_window.resize_to(1280, 900)
    visit root_path

    find_button("メニュー").send_keys(:enter)
    expect(page).to have_css("#account-menu:not([hidden])")
    expect(page).to have_css('button[aria-controls="account-menu"][aria-expanded="true"]')

    press_tab
    expect(page.evaluate_script("document.querySelector('#account-menu').contains(document.activeElement)")).to be(true)

    find_button("メニュー").send_keys(:enter)
    expect(page).to have_css("#account-menu[hidden]", visible: :all)
    expect(page).to have_css('button[aria-controls="account-menu"][aria-expanded="false"]')
  end

  it "draws every list, detail and form action with the shared button component" do
    sign_in_as_admin
    page.current_window.resize_to(1280, 900)

    actions = every_screen.flat_map do |path|
      visit path
      page.evaluate_script(CrossScreenAudit::NAMED_CONTROLS)
        .select { |control| CrossScreenAudit::ACTION_LABELS.include?(control.fetch("name")) }
        .map { |control| control.merge("path" => path) }
    end

    expect(actions.map { |control| control.fetch("name") }.uniq).to match_array(CrossScreenAudit::ACTION_LABELS)

    strays = actions.reject { |control| control.fetch("classes").include?(CrossScreenAudit::SHARED_BUTTON_SHAPE) }
    expect(strays).to be_empty, "actions drawn outside the shared button component:\n" +
      strays.map { |control| %(#{control['path']}: #{control['name']} as <#{control['tag']} class="#{control['classes']}">) }.join("\n")
  end

  it "exempts only inline links that are part of running text" do
    sign_in_as_admin
    visit root_path
    page.execute_script(<<~JS)
      document.body.insertAdjacentHTML("beforeend", `
        <div><a href="#standalone">standalone audit probe</a></div>
        <p>Running text <a href="#running">running audit probe</a>.</p>
        <p>Nested running text <em><a href="#nested-running">nested running audit probe</a></em>.</p>
      `)
    JS

    offenders = page.evaluate_script(CrossScreenAudit::SMALL_TARGETS)
    expect(offenders.grep(/standalone audit probe/)).not_to be_empty
    expect(offenders.grep(/running audit probe/)).to be_empty
    expect(offenders.grep(/nested running audit probe/)).to be_empty
  end

  it "rejects a focused control without an indicator" do
    sign_in_as_admin
    visit root_path
    page.execute_script(<<~JS)
      document.body.insertAdjacentHTML("beforeend", '<button id="focus-probe">focus probe</button>')
      document.styleSheets[0].insertRule("#focus-probe:focus-visible { outline: none !important; box-shadow: none !important; }")
      document.querySelector("#focus-probe").focus()
    JS

    result = page.evaluate_script(CrossScreenAudit::FOCUS_INDICATOR)
    expect(result.fetch("indicated")).to be(false), result.inspect
  end

  it "fails when the keyboard walk reaches its safety limit" do
    sign_in_as_admin
    visit root_path
    start_from_the_top_of(root_path)

    expect { walk_with_tab(root_path, limit: 1) }.to raise_error(/exceeded the 1-stop keyboard audit limit/)
  end

  private
    def every_screen
      @every_screen ||= begin
        records = audit
        [
          root_path,
          root_path(view: "gallery"),
          scenario_path(records[:scenario]),
          new_scenario_path,
          edit_scenario_path(records[:scenario]),
          scenario_order_index_path,
          play_sessions_path,
          play_session_path(records[:play_session]),
          new_play_session_path,
          edit_play_session_path(records[:play_session]),
          people_path,
          person_path(records[:member]),
          new_person_path,
          edit_person_path(records[:member]),
          authors_path,
          author_path(records[:author]),
          new_author_path,
          edit_author_path(records[:author]),
          game_systems_path,
          game_system_path(records[:game_system]),
          new_game_system_path,
          edit_game_system_path(records[:game_system]),
          manage_groups_path,
          manage_group_path(records[:group]),
          edit_manage_group_path(records[:group]),
          manage_users_path,
          manage_user_path(records[:user]),
          edit_manage_user_path(records[:user]),
          manage_site_setting_path,
          edit_manage_site_setting_path,
          scenario_path(-1)
        ]
      end
    end

    def build_audit_fixtures
      admin = create(:person, roles: %w[admin gm], display_name: "監査する管理者")
      member = create(:person, display_name: "折り返しを確かめるための長い表示名のメンバー")
      member.person_aliases.create!(name: "公開する別名", context: "長い名前のコミュニティ", visible: true)
      author = create(:author, name: "折り返しを確かめるための長い作者名")
      game_system = create(:game_system, name: "折り返しを確かめるための長いゲームシステム名")
      scenario = create(:scenario, title: "監査シナリオ", synopsis: "あらすじ", preparation_note: "準備情報",
        authors: [ author ], game_systems: [ game_system ])
      scenario.purchase_links.create!(label: "BOOTH", url: "https://example.com/booth")
      scenario.stream_links.create!(label: "折り返しを確かめるための長い配信名", url: "https://example.com/stream")
      play_session = create(:play_session, scenario:)
      create(:participation, play_session:, person: admin, role: :gm)
      schedule = create(:session_schedule, play_session:)
      create(:recording_link, session_schedule: schedule)

      {
        admin:,
        member:,
        author:,
        game_system:,
        scenario:,
        play_session:,
        group: create(:group, name: "折り返しを確かめるための長いグループ名", people: [ member ]),
        user: create(:user, person: member, email: "audited-account@example.com"),
        admin_user: create(:user, person: admin)
      }
    end

    def sign_in_as_admin
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: audit[:admin_user].google_uid, info: { email: audit[:admin_user].email }
      )
      sign_in_with_google
      expect(page).to have_link(audit[:admin].display_name)
    end

    def press_tab
      page.driver.browser.action.send_keys(:tab).perform
    end

    # visit の直後に Tab を送ると、まだ前の画面が居ることがある。読み込みを待ってから焦点を先頭へ戻す。
    def start_from_the_top_of(path)
      expect(page).to have_css("main#main-content"), path
      page.evaluate_script("document.activeElement && document.activeElement.blur()")
    end

    # body へ戻るか、先頭の停留点へ一周するまで辿る。
    def walk_with_tab(path, limit: 80)
      stops = []
      completed = false
      limit.times do
        press_tab
        stop = page.evaluate_script(CrossScreenAudit::FOCUS_INDICATOR)
        if stop.nil? || (stops.any? && stops.first == stop && stops.size > 1)
          completed = true
          break
        end

        stops << stop
      end
      raise "#{path} never handed focus to a control" if stops.empty?
      raise "#{path} exceeded the #{limit}-stop keyboard audit limit" unless completed

      stops
    end
end
