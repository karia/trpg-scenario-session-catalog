module Manage
  class SiteSettingsController < BaseController
    def show
      @site_setting = authorize SiteSetting.current
    end

    def edit
      @site_setting = authorize SiteSetting.current
    end

    def update
      @site_setting = authorize SiteSetting.current, :update?
      @site_setting.google_analytics_measurement_id = site_setting_params[:google_analytics_measurement_id].strip

      if @site_setting.save
        redirect_to manage_site_setting_path, notice: "サイト全体設定を更新しました"
      else
        render :edit, status: :unprocessable_content
      end
    end

    private
      def site_setting_params
        params.expect(site_setting: [ :google_analytics_measurement_id ])
      end
  end
end
