require "rails_helper"

RSpec.describe "Manage site settings" do
  describe "authorization" do
    it "lets an administrator view and edit the settings" do
      sign_in_as create(:person, roles: %w[admin])

      get manage_site_setting_path
      expect(response).to have_http_status(:ok)

      get edit_manage_site_setting_path

      expect(response).to have_http_status(:ok)
    end

    it "hides the settings from a GM" do
      sign_in_as create(:person, roles: %w[gm])

      get edit_manage_site_setting_path

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "updating" do
    before { sign_in_as create(:person, roles: %w[admin]) }

    it "stores a GA4 measurement ID" do
      patch manage_site_setting_path, params: {
        site_setting: { google_analytics_measurement_id: "G-ABC123DEF4" }
      }

      expect(response).to redirect_to(manage_site_setting_path)
      expect(SiteSetting.current.google_analytics_measurement_id).to eq("G-ABC123DEF4")
    end

    it "accepts an empty value to disable analytics" do
      SiteSetting.current.update!(google_analytics_measurement_id: "G-ABC123DEF4")

      patch manage_site_setting_path, params: {
        site_setting: { google_analytics_measurement_id: "" }
      }

      expect(SiteSetting.current.google_analytics_measurement_id).to eq("")
    end

    it "rejects a value that is not a GA4 measurement ID" do
      patch manage_site_setting_path, params: {
        site_setting: { google_analytics_measurement_id: "UA-1234-1" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("G- から始まる測定 ID を入力してください")
      expect(response.body).to include("詳細に戻る")
      expect(SiteSetting.current.google_analytics_measurement_id).to eq("")
    end
  end
end
