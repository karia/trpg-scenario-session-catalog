require "rails_helper"

RSpec.describe RefreshBoothImageJob do
  it "runs an automatic refresh for the scenario" do
    scenario = create(:scenario)
    importer = instance_double(BoothImageImporter)
    allow(BoothImageImporter).to receive(:new).with(scenario).and_return(importer)
    allow(importer).to receive(:call)

    described_class.perform_now(scenario.id)

    expect(importer).to have_received(:call).with(force: false)
  end
end
