require "rails_helper"

# 画像でないファイルが添付されると variant の生成で例外になり、
# 一覧を開いた全員に 500 が出る。添付の時点で弾く。
RSpec.describe "Attachment validation" do
  def upload(content, type, name)
    file = Tempfile.new
    file.binmode
    file.write(content)
    file.close
    Rack::Test::UploadedFile.new(file.path, type, original_filename: name)
  ensure
    file&.unlink
  end

  def png
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/dot.png"), "image/png")
  end

  describe Person do
    it "accepts a PNG icon" do
      person = create(:person)
      person.icon.attach(png)

      expect(person).to be_valid
    end

    it "rejects a file that is not an image" do
      person = create(:person)
      person.icon.attach(upload("not an image", "text/plain", "evil.txt"))

      expect(person).not_to be_valid
      expect(person.errors[:icon]).to be_present
    end

    it "rejects a GIF icon" do
      person = create(:person)
      person.icon.attach(upload("GIF89a", "image/gif", "animated.gif"))

      expect(person).not_to be_valid
    end

    it "rejects a malformed file declared as a PNG icon" do
      person = create(:person)
      person.icon.attach(upload("not an image", "image/png", "broken.png"))

      expect(person).not_to be_valid
    end

    it "rejects an image that is too large to be an icon" do
      person = create(:person)
      person.icon.attach(upload("x" * 6.megabytes, "image/png", "huge.png"))

      expect(person).not_to be_valid
    end
  end

  describe Scenario do
    it "rejects a jacket that is not an image" do
      scenario = create(:scenario)
      scenario.jacket.attach(upload("not an image", "text/plain", "evil.txt"))

      expect(scenario).not_to be_valid
    end

    it "rejects a GIF jacket" do
      scenario = create(:scenario)
      scenario.jacket.attach(upload("GIF89a", "image/gif", "animated.gif"))

      expect(scenario).not_to be_valid
    end

    it "rejects a malformed file declared as a PNG jacket" do
      scenario = create(:scenario)
      scenario.jacket.attach(upload("not an image", "image/png", "broken.png"))

      expect(scenario).not_to be_valid
    end

    it "rejects an imported BOOTH file that is not an image" do
      scenario = create(:scenario)
      scenario.booth_image.attach(upload("not an image", "text/plain", "evil.txt"))

      expect(scenario).not_to be_valid
    end
  end
end
