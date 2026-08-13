require "rails_helper"

RSpec.describe ApplicationController do
  it "verifies that every action performed an authorization check" do
    filters = described_class._process_action_callbacks.map(&:filter)

    expect(filters).to include(:verify_authorized)
  end

  it "answers 404 rather than 403 when authorization fails" do
    handler = described_class.rescue_handlers.to_h.fetch("Pundit::NotAuthorizedError")

    expect(handler).to eq(:render_not_found)
  end
end
