# Google OAuth — credentials via ENV (dotenv-rails in development/test; Heroku Config Vars in production).
#
# Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client (Web application):
#   Authorized JavaScript origins:  APP_HOST origin (e.g. http://localhost:3000)
#   Authorized redirect URIs:     APP_HOST + /auth/google_oauth2/callback
#
# Production (Heroku): set Config Vars:
#   APP_HOST=https://your-app.herokuapp.com   (recommended; must use https)
#   GOOGLE_CLIENT_ID=...
#   GOOGLE_CLIENT_SECRET=...
#
# If APP_HOST is unset on Heroku, HEROKU_APP_NAME is used automatically.

require "omniauth"
require_relative "../../lib/omniauth_host"

OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true

full_host = OmniauthHost.resolve
if full_host.blank? && Rails.env.production?
  Rails.logger.warn(
    "[OmniAuth] APP_HOST is not set and HEROKU_APP_NAME is missing. " \
    "Google sign-in redirect URLs will be wrong. " \
    "Set APP_HOST to your public URL (e.g. https://your-app.herokuapp.com)."
  )
end
OmniAuth.config.full_host = full_host

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
  Rails.logger.info "[OmniAuth] Google OAuth disabled: set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET"
end
