require "rails_helper"

RSpec.describe User do
  it "requires a Google UID" do
    expect(build(:user, google_uid: "")).not_to be_valid
  end

  it "rejects a duplicate Google UID" do
    create(:user, google_uid: "1234")

    expect(build(:user, google_uid: "1234")).not_to be_valid
  end

  it "is valid without a person, which is how every account starts" do
    expect(build(:user, person: nil)).to be_valid
  end

  it "lets at most one account point at a person" do
    person = create(:person)
    create(:user, person: person)

    expect(build(:user, person: person)).not_to be_valid
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
  end
end
