require "rails_helper"

RSpec.describe HttpUrlValidator do
  subject(:record) { StreamLink.new(scenario: build(:scenario), url: url) }

  context "with an https URL" do
    let(:url) { "https://booth.pm/ja/items/1" }

    it { is_expected.to be_valid }
  end

  context "with an http URL" do
    let(:url) { "http://example.com" }

    it { is_expected.to be_valid }
  end

  context "with a javascript scheme" do
    let(:url) { "javascript:alert(1)" }

    it { is_expected.not_to be_valid }
  end

  context "with an http prefix followed by a newline" do
    let(:url) { "https://ok.example\njavascript:alert(1)" }

    it { is_expected.not_to be_valid }
  end

  context "without a host" do
    let(:url) { "https://" }

    it { is_expected.not_to be_valid }
  end
end
