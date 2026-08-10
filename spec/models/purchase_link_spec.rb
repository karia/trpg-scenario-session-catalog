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
end
