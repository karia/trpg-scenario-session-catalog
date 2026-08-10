require "rails_helper"

RSpec.describe SpoilerReveal do
  it "records that a person opened a scenario's preparation note" do
    reveal = create(:spoiler_reveal)

    expect(reveal.person.spoiler_reveals).to include(reveal)
  end

  it "does not record the same pair twice" do
    reveal = create(:spoiler_reveal)

    expect(build(:spoiler_reveal, person: reveal.person, scenario: reveal.scenario)).not_to be_valid
  end

  it "is remembered per person, so another device sees the same state" do
    reveal = create(:spoiler_reveal)

    expect(reveal.person.revealed?(reveal.scenario)).to be(true)
    expect(create(:person).revealed?(reveal.scenario)).to be(false)
  end
end
