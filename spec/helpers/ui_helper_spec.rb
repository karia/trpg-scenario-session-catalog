require "rails_helper"

RSpec.describe UiHelper, type: :helper do
  describe "#ui_button" do
    it "renders a semantic button with a controlled variant" do
      html = helper.ui_button("保存", variant: :primary, type: "submit", data: { testid: "save" })
      button = Capybara.string(html).find("button")

      expect(button).to have_text("保存")
      expect(button[:type]).to eq("submit")
      expect(button["data-testid"]).to eq("save")
      expect(button[:class]).to include("bg-ui-action", "min-h-11")
    end

    it "rejects an unknown variant" do
      expect { helper.ui_button("保存", variant: :unknown) }.to raise_error(KeyError)
    end
  end

  describe "#ui_button_link" do
    it "renders navigation with the same controlled button styles" do
      html = helper.ui_button_link("編集", href: "/scenarios/1/edit", variant: :secondary, size: :small)
      link = Capybara.string(html).find("a")

      expect(link[:href]).to eq("/scenarios/1/edit")
      expect(link[:class]).to include("bg-ui-surface-solid", "min-h-11", "px-3")
    end
  end

  describe "#ui_field and #ui_input" do
    let(:scenario) { Scenario.new }

    it "associates the label and description with the input" do
      html = render_field(label: "タイトル", description: "公開される名称です")
      field = Capybara.string(html)

      expect(field).to have_css('label[for="scenario_title"]', text: "タイトル")
      expect(field).to have_css("#scenario_title_description", text: "公開される名称です")
      expect(field).to have_css('#scenario_title[aria-describedby="scenario_title_description"]')
      expect(field).to have_css("#scenario_title.text-base.min-h-11")
    end

    it "renders and associates a validation error without duplicate IDs" do
      scenario.errors.add(:title, "を入力してください")
      html = render_field(label: "タイトル")
      field = Capybara.string(html)

      expect(field).to have_css('#scenario_title[aria-invalid="true"][aria-describedby="scenario_title_error"]')
      expect(field).to have_css("#scenario_title_error", text: "を入力してください", count: 1)
      expect(field).to have_no_css("[data-ui-error-id]")
    end

    private
      def render_field(label:, description: nil)
        helper.form_with(model: scenario, url: "/") do |form|
          helper.ui_field(form, :title, label:, description:) do |field|
            helper.ui_input(form, :title, described_by: field[:described_by])
          end
        end
      end
  end

  describe "form controls" do
    let(:scenario) { Scenario.new }

    it "associates textarea and select controls with field descriptions" do
      textarea = helper.form_with(model: scenario, url: "/") do |form|
        helper.ui_field(form, :synopsis, description: "公開される本文です") do |field|
          helper.ui_textarea(form, :synopsis, described_by: field[:described_by])
        end
      end
      select = helper.form_with(model: scenario, url: "/") do |form|
        helper.ui_field(form, :character_sheet_deadline, description: "期限を選びます") do |field|
          helper.ui_select(form, :character_sheet_deadline, [ [ "未設定", "" ] ], described_by: field[:described_by])
        end
      end

      expect(Capybara.string(textarea)).to have_css('textarea[aria-describedby="scenario_synopsis_description"]')
      expect(Capybara.string(select)).to have_css('select[aria-describedby="scenario_character_sheet_deadline_description"]')
    end

    it "renders one associated validation error for a textarea" do
      scenario.errors.add(:synopsis, "が長すぎます")
      html = helper.form_with(model: scenario, url: "/") do |form|
        helper.ui_field(form, :synopsis) do |field|
          helper.ui_textarea(form, :synopsis, described_by: field[:described_by])
        end
      end
      field = Capybara.string(html)

      expect(field).to have_css('#scenario_synopsis[aria-invalid="true"][aria-describedby="scenario_synopsis_error"]')
      expect(field).to have_css('#scenario_synopsis_error[data-error-attribute="synopsis"]', count: 1)
    end

    it "renders semantic checkbox and radio controls with 44px targets" do
      checkbox = helper.form_with(model: scenario, url: "/") do |form|
        helper.ui_checkbox(form, :read, label: "既読")
      end
      radio = helper.ui_radio("scenario_status[read]", "1", label: "あり", checked: true, id: "status_read_yes")

      expect(Capybara.string(checkbox)).to have_css('label.min-h-11 input[type="checkbox"]')
      expect(Capybara.string(radio)).to have_css('label.min-h-11 input#status_read_yes[type="radio"][checked]')
    end
  end

  describe "#ui_error_summary" do
    it "keeps accessible error links used by the focus controller" do
      scenario = Scenario.new
      scenario.errors.add(:title, "を入力してください")
      summary = Capybara.string(helper.ui_error_summary(scenario))

      expect(summary).to have_css('[role="alert"][data-controller="error-summary"]')
      expect(summary).to have_css('a[data-error-attribute="title"]', text: scenario.errors.full_messages.first)
    end

    it "renders form-wide errors without a dead field link" do
      play_session = PlaySession.new
      play_session.errors.add(:base, "同じ人を複数の行に指定できません")
      summary = Capybara.string(helper.ui_error_summary(play_session))

      expect(summary).to have_text("同じ人を複数の行に指定できません")
      expect(summary).to have_no_link
    end
  end
end
