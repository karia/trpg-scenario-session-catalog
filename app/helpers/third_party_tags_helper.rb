module ThirdPartyTagsHelper
  # ログイン中に解析タグと広告タグを出すと、閲覧者と非公開の情報が外部へ渡る。
  # Phase 2 が current_user を実装すると、そのまま非ログイン時のみに絞られる。
  def signed_out?
    current_user.nil?
  end

  def show_analytics?
    signed_out? && ENV["GA_MEASUREMENT_ID"].present?
  end

  def show_ads?
    signed_out? && ENV["ADSENSE_CLIENT_ID"].present?
  end
end
