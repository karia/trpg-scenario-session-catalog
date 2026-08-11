require "rails_helper"

RSpec.describe RecordingLink do
  it "rejects a URL that is not an http URL" do
    expect(build(:recording_link, url: "javascript:alert(1)")).not_to be_valid
  end
end
