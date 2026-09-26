require "rails_helper"

RSpec.describe ScenarioStatus do
  it "belongs to one person and scenario only once" do
    status = create(:scenario_status)

    duplicate = build(:scenario_status, person: status.person, scenario: status.scenario)

    expect(duplicate).not_to be_valid
  end
end
