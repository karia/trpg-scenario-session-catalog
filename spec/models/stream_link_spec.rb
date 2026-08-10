require "rails_helper"

RSpec.describe StreamLink do
  it "requires a URL, unlike a purchase link" do
    expect(build(:stream_link, url: nil)).not_to be_valid
  end

  it "rejects something that is not an http URL" do
    expect(build(:stream_link, url: "ftp://example.com/a")).not_to be_valid
  end
end
