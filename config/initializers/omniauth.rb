# Google OAuth — load credentials from `.env` (dotenv-rails in development/test).
# Google Cloud Console → OAuth 2.0 Client (Web):
#   Authorized JavaScript origins: e.g. http://localhost:3000
#   Authorized redirect URIs:       e.g. http://localhost:3000/auth/google_oauth2/callback
#
# Set APP_HOST to the same origin you use in the browser (scheme + host + port).

require "omniauth"

OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true

OmniAuth.config.full_host =
  ENV["APP_HOST"].presence ||
  (Rails.env.development? ? "http://localhost:3000" : nil)

if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
             ENV.fetch("GOOGLE_CLIENT_ID"),
             ENV.fetch("GOOGLE_CLIENT_SECRET"),
             {
               scope: "email,profile,openid",
               prompt: "select_account",
               access_type: "online"
             }
  end
elsif Rails.env.local?
  Rails.logger.info "[OmniAuth] Google OAuth disabled: set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in .env"
end
