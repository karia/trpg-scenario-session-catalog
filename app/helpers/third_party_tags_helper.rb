module ThirdPartyTagsHelper
  # ログイン中に解析タグと広告タグを出すと、閲覧者と非公開の情報が外部へ渡る。
  def show_analytics?
    !signed_in? && ENV["GA_MEASUREMENT_ID"].present?
  end

  def show_ads?
    !signed_in? && ENV["ADSENSE_CLIENT_ID"].present?
  end
end
