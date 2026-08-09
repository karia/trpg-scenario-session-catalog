require "rails_helper"

RSpec.describe "Active Storage" do
  it "stores a blob and reads the same bytes back" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("jacket"),
      filename: "jacket.txt",
      content_type: "text/plain"
    )

    expect(blob.download).to eq("jacket")
  end
end
