require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#youtube_embed_url" do
    it "converts supported YouTube URLs to privacy-enhanced embed URLs" do
      expect(helper.youtube_embed_url("https://youtu.be/dQw4w9WgXcQ?t=43"))
        .to eq("https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ")
      expect(helper.youtube_embed_url("https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=example"))
        .to eq("https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ")
      expect(helper.youtube_embed_url("https://youtube.com/shorts/dQw4w9WgXcQ"))
        .to eq("https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ")
      expect(helper.youtube_embed_url("https://youtube.com/live/dQw4w9WgXcQ"))
        .to eq("https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ")
    end

    it "returns nil for other hosts and malformed video IDs" do
      expect(helper.youtube_embed_url("https://example.com/watch?v=dQw4w9WgXcQ")).to be_nil
      expect(helper.youtube_embed_url("https://youtube.com/watch?v=not/valid")).to be_nil
    end

    it "returns nil when the query string is malformed" do
      expect(helper.youtube_embed_url("https://youtube.com/watch?v=dQw4w9WgXcQ&x=%")).to be_nil
    end
  end
end
