require "rails_helper"

RSpec.describe Authentication do
  let(:controller_class) { Class.new(ActionController::Base) { include Authentication } }

  it "has no current user until Phase 2 implements Google sign-in" do
    expect(controller_class.new.current_user).to be_nil
  end

  it "is included in ApplicationController" do
    expect(ApplicationController.ancestors).to include(described_class)
  end
end
