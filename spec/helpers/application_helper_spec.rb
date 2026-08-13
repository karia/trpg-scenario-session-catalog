require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#auto_link_urls" do
    it "links HTTP URLs in escaped plain text and opens them in a new tab" do
      html = helper.auto_link_urls("参考: https://example.com/path?q=1&lang=ja\n<script>alert(1)</script>")

      page = Capybara.string(html)
      expect(page).to have_link(
        "https://example.com/path?q=1&lang=ja",
        href: "https://example.com/path?q=1&lang=ja",
        target: "_blank"
      )
      expect(page).to have_css('a[rel="noopener"]')
      expect(html).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
      expect(html).not_to include("<script>")
    end

    it "leaves non-HTTP schemes as plain text" do
      html = helper.auto_link_urls("javascript:alert(1) ftp://example.com/file")

      expect(Capybara.string(html)).to have_no_link
    end
  end

  describe "#youtube_embed_url" do
    it "converts supported YouTube URLs to embed URLs" do
      expect(helper.youtube_embed_url("https://youtu.be/dQw4w9WgXcQ?t=43"))
        .to eq("https://www.youtube.com/embed/dQw4w9WgXcQ")
      expect(helper.youtube_embed_url("https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=example"))
        .to eq("https://www.youtube.com/embed/dQw4w9WgXcQ")
      expect(helper.youtube_embed_url("https://youtube.com/shorts/dQw4w9WgXcQ"))
        .to eq("https://www.youtube.com/embed/dQw4w9WgXcQ")
      expect(helper.youtube_embed_url("https://youtube.com/live/dQw4w9WgXcQ"))
        .to eq("https://www.youtube.com/embed/dQw4w9WgXcQ")
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
