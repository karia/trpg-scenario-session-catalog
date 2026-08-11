require "rails_helper"

RSpec.describe BoothImageImporter do
  let(:scenario) { create(:scenario) }
  let(:client) { instance_double(BoothHttpClient) }
  let(:page_url) { "https://booth.pm/ja/items/1" }
  let(:image_url) { "https://booth.pximg.net/item.jpg" }

  before { scenario.purchase_links.create!(label: "BOOTH", url: page_url) }

  it "imports the og:image and records its source page" do
    allow(client).to receive(:get).with(page_url, kind: :page).and_return(
      BoothHttpClient::Response.new(body: %(<meta property="og:image" content="#{image_url}">), content_type: "text/html")
    )
    allow(client).to receive(:get).with(image_url, kind: :image).and_return(
      BoothHttpClient::Response.new(body: File.binread(Rails.root.join("spec/fixtures/files/dot.png")), content_type: "image/png")
    )

    result = described_class.new(scenario, client:).call(force: false)

    expect(result).to be_success
    expect(scenario.booth_image).to be_attached
    expect(scenario.booth_image.blob.metadata["source_url"]).to eq(page_url)
  end

  it "does not fetch the same source again automatically" do
    allow(client).to receive(:get)
    scenario.booth_image.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "old.png", content_type: "image/png",
      metadata: { source_url: page_url }
    )

    result = described_class.new(scenario, client:).call(force: false)

    expect(result).to be_success
    expect(client).not_to have_received(:get)
  end

  it "keeps the existing image when a forced refresh fails" do
    scenario.booth_image.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "old.png", content_type: "image/png"
    )
    old_blob = scenario.booth_image.blob
    allow(client).to receive(:get).and_raise(BoothHttpClient::Error, "timeout")

    result = described_class.new(scenario, client:).call(force: true)

    expect(result).not_to be_success
    expect(scenario.reload.booth_image.blob).to eq(old_blob)
  end

  it "keeps the existing image when the downloaded body is not really an image" do
    scenario.booth_image.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "old.png", content_type: "image/png"
    )
    old_blob = scenario.booth_image.blob
    allow(client).to receive(:get).with(page_url, kind: :page).and_return(
      BoothHttpClient::Response.new(body: %(<meta property="og:image" content="#{image_url}">), content_type: "text/html")
    )
    allow(client).to receive(:get).with(image_url, kind: :image).and_return(
      BoothHttpClient::Response.new(body: "not really a JPEG", content_type: "image/jpeg")
    )

    result = described_class.new(scenario, client:).call(force: true)

    expect(result).not_to be_success
    expect(scenario.reload.booth_image.blob).to eq(old_blob)
  end

  it "removes a stale imported image automatically when no BOOTH URL remains" do
    scenario.booth_image.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "old.png", content_type: "image/png"
    )
    scenario.purchase_links.destroy_all

    result = described_class.new(scenario, client:).call(force: false)

    expect(result).to be_success
    expect(scenario.booth_image).not_to be_attached
  end
end
