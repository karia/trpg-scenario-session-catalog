require "rails_helper"

RSpec.describe PurchaseLink do
  it "requires a label" do
    expect(build(:purchase_link, label: "")).not_to be_valid
  end

  it "allows a label without a URL, for rows like 「書籍購入者限定特典」" do
    expect(build(:purchase_link, label: "書籍購入者限定特典", url: nil)).to be_valid
  end

  it "rejects something that is not an http URL" do
    expect(build(:purchase_link, url: "javascript:alert(1)")).not_to be_valid
  end

  it "recognizes BOOTH and its shop subdomains without accepting lookalikes" do
    expect(build(:purchase_link, url: "https://booth.pm/ja/items/1")).to be_booth
    expect(build(:purchase_link, url: "https://example.booth.pm/items/1")).to be_booth
    expect(build(:purchase_link, url: "https://evilbooth.pm/items/1")).not_to be_booth
  end

  it "queues a BOOTH image refresh after the link is saved" do
    scenario = create(:scenario)

    expect { create(:purchase_link, scenario:) }
      .to have_enqueued_job(RefreshBoothImageJob).with(scenario.id)
  end
end
