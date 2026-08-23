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
end
