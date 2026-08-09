require "rails_helper"

RSpec.describe ApplicationController do
  it "verifies that every action performed an authorization check" do
    filters = described_class._process_action_callbacks.map(&:filter)

    expect(filters).to include(:verify_authorized)
  end

  it "answers 404 rather than 403 when authorization fails" do
    controller = described_class.new
    allow(controller).to receive(:head)

    controller.rescue_with_handler(Pundit::NotAuthorizedError.new)

    expect(controller).to have_received(:head).with(:not_found)
  end
end
