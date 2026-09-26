require "rails_helper"

RSpec.describe Person do
  describe "#google_oauth_scopes" do
    it "allows only identity scopes without a privileged role" do
      expect(build(:person).google_oauth_scopes).to contain_exactly("email", "profile")
    end

    it "allows YouTube access for a GM or administrator" do
      %w[gm admin].each do |role|
        expect(create(:person, roles: [ role ]).google_oauth_scopes)
          .to include("https://www.googleapis.com/auth/youtube.force-ssl")
      end
    end
  end

  it "requires a display name" do
    expect(build(:person, display_name: "")).not_to be_valid
  end

  it "requires a unique valid Discord UID when prelinked" do
    create(:person, discord_uid: "12345678901234567#{8}")

    expect(build(:person, discord_uid: "12345678901234567#{8}")).not_to be_valid
    expect(build(:person, discord_uid: "not-an-id")).not_to be_valid
    expect(build(:person, discord_uid: "")).to be_valid
  end

  it "rejects a Discord UID already used by an account" do
    uid = "23456789012345678#{9}"
    create(:user, provider: "discord", uid:, person: nil)

    expect(build(:person, discord_uid: uid)).not_to be_valid
  end

  describe "roles" do
    it "starts with none" do
      expect(create(:person)).not_to be_admin
    end

    it "takes more than one role at once" do
      person = create(:person, roles: %w[admin gm])

      expect(person).to be_admin
      expect(person).to be_gm
    end

    it "rejects a role outside the known set" do
      person = create(:person)

      expect(person.person_roles.build(name: "owner")).not_to be_valid
    end

    it "does not grant the same role twice" do
      person = create(:person, roles: %w[gm])

      expect(person.person_roles.build(name: "gm")).not_to be_valid
    end

    it "revokes Google access after losing both privileged roles" do
      create(:person, roles: %w[admin])
      person = create(:person, roles: %w[admin gm])
      user = create(:user, person:, google_refresh_token: "refresh-token")
      allow(GoogleTokenRevoker).to receive(:revoke)

      person.update!(roles: [])

      expect(GoogleTokenRevoker).to have_received(:revoke).with("refresh-token")
      expect(user.reload.google_refresh_token).to be_nil
    end

    it "keeps Google access while either privileged role remains" do
      create(:person, roles: %w[admin])
      person = create(:person, roles: %w[admin gm])
      user = create(:user, person:, google_refresh_token: "refresh-token")
      allow(GoogleTokenRevoker).to receive(:revoke)

      person.update!(roles: %w[gm])

      expect(GoogleTokenRevoker).not_to have_received(:revoke)
      expect(user.reload.google_refresh_token).to eq("refresh-token")
    end
  end

  it "revokes Google access when destroyed" do
    person = create(:person)
    user = create(:user, person:, google_refresh_token: "refresh-token")
    allow(GoogleTokenRevoker).to receive(:revoke)

    person.destroy!

    expect(GoogleTokenRevoker).to have_received(:revoke).with("refresh-token")
    expect(user.reload).to have_attributes(person: nil, google_refresh_token: nil)
  end

  describe "groups" do
    it "belongs to more than one group" do
      person = create(:person)
      person.groups << create(:group, name: "よく遊ぶ人たち")
      person.groups << create(:group, name: "ペア卓")

      expect(person.groups.map(&:name)).to contain_exactly("よく遊ぶ人たち", "ペア卓")
    end
  end

  # resize_to_fill は resize_to_limit と別の引数の組み立てを通るため、別に見る。
  describe "icon variant" do
    it "keeps sharpening" do
      variants = described_class.reflect_on_attachment(:icon).named_variants

      expect(variants[:thumb].transformations[:resize_to_fill]).to eq([ 160, 160, { sharpen: true } ])
    end

    it "actually processes" do
      person = create(:person)
      person.icon.attach(
        Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/dot.png"), "image/png")
      )

      expect { person.icon.variant(:thumb).processed }.not_to raise_error
    end
  end
end
