require "rails_helper"

RSpec.describe "Avo mount point" do
  it "is not reachable until Phase 1 puts a guard in front of it" do
    get "/avo"

    expect(response).to have_http_status(:not_found)
  end
end
