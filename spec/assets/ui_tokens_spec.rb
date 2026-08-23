require "rails_helper"

RSpec.describe "UI design tokens" do
  let(:stylesheet) { Rails.root.join("app/assets/tailwind/application.css").read }

  it "no longer carries the colors of the light design" do
    expect(stylesheet).not_to match(/--color-(ink|paper|surface|seal|muted|rule):/)
  end

  it "paints the dark ground in the base layer so no render path falls back to light" do
    base = stylesheet[/@layer base \{.*?^\}/m]

    expect(base).to include("background-color: var(--color-ui-background);", "color: var(--color-ui-text);")
  end

  it "provides sufficient contrast for strong outlines and semantic colors" do
    expect(contrast(token("ui-outline-strong"), token("ui-surface-solid"))).to be >= 3
    expect(contrast(token("ui-outline-strong"), token("ui-field-solid"))).to be >= 3
    expect(contrast(token("ui-on-danger"), token("ui-danger"))).to be >= 4.5
    expect(contrast(token("ui-error"), token("ui-surface-solid"))).to be >= 4.5
    expect(contrast(token("ui-error"), token("ui-field-solid"))).to be >= 4.5
  end

  it "keeps stacking tokens outside Tailwind's theme namespaces" do
    theme = stylesheet[/@theme \{.*?^\}/m]

    expect(theme).not_to include("--z-ui-")
    expect(stylesheet).to include("--z-ui-header: 30;", "--z-ui-overlay: 40;", "--z-ui-toast: 50;")
  end

  private
    def token(name)
      stylesheet.match(/--color-#{Regexp.escape(name)}:\s*(#[0-9a-f]{6});/i).captures.first
    end

    def contrast(foreground, background)
      lighter, darker = [ luminance(foreground), luminance(background) ].sort.reverse
      (lighter + 0.05) / (darker + 0.05)
    end

    def luminance(color)
      channels = color.delete_prefix("#").scan(/../).map { |channel| channel.to_i(16) / 255.0 }
      red, green, blue = channels.map { |channel| channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055)**2.4 }
      0.2126 * red + 0.7152 * green + 0.0722 * blue
    end
end
