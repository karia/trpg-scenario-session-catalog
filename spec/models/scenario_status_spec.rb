require "rails_helper"

RSpec.describe ScenarioStatus do
  it "belongs to one person and scenario only once" do
    status = create(:scenario_status)

    duplicate = build(:scenario_status, person: status.person, scenario: status.scenario)

    expect(duplicate).not_to be_valid
  end

  it "uses the highest-priority status label" do
    scenario = create(:scenario, game_systems: [ create(:game_system, game_master_label: "KP") ])

    expect(build(:scenario_status, scenario:, gm_experienced: true, pl_experienced: true, read: true).label)
      .to eq("KP経験あり")
    expect(build(:scenario_status, scenario:, pl_experienced: true, read: true).label).to eq("PL経験あり")
    expect(build(:scenario_status, scenario:, read: true).label).to eq("シナリオ既読")
    expect(build(:scenario_status, scenario:).label).to eq("シナリオ所持")
  end
end
