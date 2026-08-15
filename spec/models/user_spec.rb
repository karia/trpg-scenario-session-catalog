require "rails_helper"

RSpec.describe User do
  it "requires a provider and UID" do
    expect(build(:user, provider: "", uid: "")).not_to be_valid
  end

  it "rejects a duplicate UID from the same provider" do
    create(:user, provider: "discord", uid: "1234")

    expect(build(:user, provider: "discord", uid: "1234")).not_to be_valid
    expect(build(:user, provider: "google_oauth2", uid: "1234")).to be_valid
  end

  it "is valid without a person, which is how every account starts" do
    expect(build(:user, person: nil)).to be_valid
  end

  it "lets at most one account from each provider point at a person" do
    person = create(:person)
    create(:user, provider: "google_oauth2", person: person)

    expect(build(:user, provider: "google_oauth2", person: person)).not_to be_valid
    expect(build(:user, provider: "discord", person: person)).to be_valid
  end

  describe ".from_google" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "10000001",
        info: { email: "someone@example.com", name: "Someone" }
      )
    end

    it "creates an account that is not linked to a person yet" do
      user = described_class.from_google(auth)

      expect(user).to be_persisted
      expect(user.person).to be_nil
      expect(user.email).to eq("someone@example.com")
    end

    it "returns the same account on the second sign-in" do
      first = described_class.from_google(auth)

      expect { described_class.from_google(auth) }.not_to change(described_class, :count)
      expect(described_class.from_google(auth)).to eq(first)
    end

    it "follows an address change without losing the link to the person" do
      user = described_class.from_google(auth)
      user.update!(person: create(:person))

      described_class.from_google(auth.merge(info: { email: "moved@example.com" }))

      expect(user.reload.email).to eq("moved@example.com")
      expect(user.person).to be_present
    end

    it "adopts an account inserted by an old application instance" do
      legacy = described_class.insert_all!([ {
        google_uid: auth.uid.to_s,
        email: "old@example.com",
        created_at: Time.current,
        updated_at: Time.current
      } ]).then { |result| described_class.find(result.rows.first.first) }

      expect(legacy.uid).to be_nil

      expect { described_class.from_google(auth) }.not_to change(described_class, :count)
      expect(legacy.reload).to have_attributes(uid: auth.uid.to_s, email: "someone@example.com")
    end
  end

  describe ".from_omniauth" do
    it "creates and finds a Discord account by provider and UID" do
      auth = OmniAuth::AuthHash.new(
        provider: "discord", uid: "20000001", info: { email: "discord@example.com", name: "Discord User" }
      )

      first = described_class.from_omniauth(auth)

      expect(first.provider).to eq("discord")
      expect(first.uid).to eq("20000001")
      expect(first.name).to eq("Discord User")
      expect { described_class.from_omniauth(auth) }.not_to change(described_class, :count)
    end
  end
end
