require "rails_helper"

RSpec.describe "Health check" do
  describe "GET /up" do
    it "returns 200 when the database is reachable" do
      get "/up"

      expect(response).to have_http_status(:ok)
    end

    it "returns 200 when the connection has not been established yet" do
      allow(ActiveRecord::Base.connection).to receive(:active?).and_return(false)

      get "/up"

      expect(response).to have_http_status(:ok)
    end

    it "returns 503 when the database is unreachable" do
      allow(ActiveRecord::Base.connection).to receive(:verify!).and_raise(ActiveRecord::ConnectionNotEstablished)

      get "/up"

      expect(response).to have_http_status(:service_unavailable)
    end
  end
end
