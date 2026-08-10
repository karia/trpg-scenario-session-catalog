require "rails_helper"

RSpec.describe Person do
  it "requires a display name" do
    expect(build(:person, display_name: "")).not_to be_valid
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
  end

  describe "groups" do
    it "belongs to more than one group" do
      person = create(:person)
      person.groups << create(:group, name: "よく遊ぶ人たち")
      person.groups << create(:group, name: "ペア卓")

      expect(person.groups.map(&:name)).to contain_exactly("よく遊ぶ人たち", "ペア卓")
    end
  end
end
