require "rails_helper"

RSpec.describe Favorite do
  it "belongs to a person and a scenario" do
    expect(build(:favorite)).to be_valid
  end

  it "does not record the same scenario twice for one person" do
    favorite = create(:favorite)

    expect(build(:favorite, person: favorite.person, scenario: favorite.scenario)).not_to be_valid
  end

  it "lets two people favour the same scenario" do
    favorite = create(:favorite)

    expect(build(:favorite, scenario: favorite.scenario)).to be_valid
  end
end
