module ThirdPartyTagsHelper
  # ログイン中に解析タグと広告タグを出すと、閲覧者と非公開の情報が外部へ渡る。
  def show_analytics?
    !signed_in? && analytics_measurement_id.present?
  end

  def analytics_measurement_id
    return @analytics_measurement_id if defined?(@analytics_measurement_id)

    @analytics_measurement_id = SiteSetting.current.google_analytics_measurement_id
  end

  def show_ads?
    !signed_in? && ENV["ADSENSE_CLIENT_ID"].present?
  end
end
