# Be sure to restart your server when you modify this file.

# 非ログイン時のみ描画する Google Analytics と AdSense の配信元を許可する。
# タグを出さない環境でも許可自体は残るが、外部への接続はタグが無ければ起きない。
GOOGLE_TAG_ORIGINS = %w[
  https://www.googletagmanager.com
  https://pagead2.googlesyndication.com
  https://googleads.g.doubleclick.net
  https://tpc.googlesyndication.com
].freeze

GOOGLE_MEASUREMENT_ORIGINS = %w[
  https://www.google-analytics.com
  https://region1.google-analytics.com
].freeze

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data, :blob, *GOOGLE_MEASUREMENT_ORIGINS, "https://www.google.com"
    policy.object_src  :none
    policy.script_src  :self, *GOOGLE_TAG_ORIGINS
    policy.style_src   :self
    policy.connect_src :self, *GOOGLE_MEASUREMENT_ORIGINS, *GOOGLE_TAG_ORIGINS
    policy.frame_src   :self, *GOOGLE_TAG_ORIGINS
    policy.frame_ancestors :none
    policy.base_uri    :self
    policy.form_action :self
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[ script-src ]
end
