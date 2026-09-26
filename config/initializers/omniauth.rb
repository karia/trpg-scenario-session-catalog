Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV["GOOGLE_CLIENT_ID"],
    ENV["GOOGLE_CLIENT_SECRET"],
    scope: "email,profile",
    access_type: "offline",
    prompt: "consent select_account",
    overridable_authorize_options: [],
    setup: lambda { |env|
      user_id = env.fetch("rack.session", {})["user_id"]
      person = User.find_by(id: user_id)&.person
      scopes = %w[email profile]
      scopes << "https://www.googleapis.com/auth/youtube.force-ssl" if person&.gm? || person&.admin?
      env.fetch("omniauth.strategy").options[:scope] = scopes.join(",")
    }

  provider :discord,
    ENV["DISCORD_CLIENT_ID"],
    ENV["DISCORD_CLIENT_SECRET"],
    scope: "identify email"
end

# 認証の開始を POST に限定する。GET のままだと外部サイトからログインを誘発できる。
OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true

OmniAuth.config.on_failure = proc { |env| SessionsController.action(:failure).call(env) }
