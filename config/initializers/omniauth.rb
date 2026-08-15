Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV["GOOGLE_CLIENT_ID"],
    ENV["GOOGLE_CLIENT_SECRET"],
    scope: "email,profile",
    prompt: "select_account"

  provider :discord,
    ENV["DISCORD_CLIENT_ID"],
    ENV["DISCORD_CLIENT_SECRET"],
    scope: "identify email"
end

# 認証の開始を POST に限定する。GET のままだと外部サイトからログインを誘発できる。
OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true

OmniAuth.config.on_failure = proc { |env| SessionsController.action(:failure).call(env) }
