# Resolves the public site origin used for OmniAuth callback URLs.
# Must match the URL in the browser and Google Cloud Console redirect URIs.
module OmniauthHost
  module_function

  def resolve
    host = normalize(ENV["APP_HOST"])
    return host if host.present?

    return "http://localhost:3000" if Rails.env.development?

    if (heroku_app = ENV["HEROKU_APP_NAME"].presence)
      return "https://#{heroku_app}.herokuapp.com"
    end

    host = normalize(ENV["APP_URL"])
    return host if host.present?

    nil
  end

  def normalize(value)
    host = value.to_s.strip
    return nil if host.blank?

    host = host.chomp("/")
    host = "https://#{host}" unless host.match?(%r{\Ahttps?://}i)
    host
  end
end
