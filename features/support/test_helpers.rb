module TestHelpers
  def bot_prevention_params(rendered_at: 1.minute.ago)
    verifier = Rails.application.message_verifier(:bot_prevention)
    {
      BotPrevention::TIMESTAMP_FIELD =>
        verifier.generate(rendered_at.to_f, purpose: :form_render_time)
    }
  end

  def create_user!(email:, password: "password", name: nil)
    User.create!(
      name: name || email.split("@").first.titleize,
      email: email,
      password: password,
      password_confirmation: password
    )
  end

  def find_user!(email)
    User.find_by!(email: email)
  end

  def find_activity!(title)
    Activity.find_by!(title: title)
  end

  def activity_params(title:, city:, category: "Hike")
    {
      title: title,
      city: city,
      category: category,
      event_date: (Date.current + 1).to_s
    }
  end

  def post_activity(title:, city:, category: "Hike")
    page.driver.post activities_path, {
      activity: activity_params(title: title, city: city, category: category)
    }.merge(bot_prevention_params)
  end

  def post_registration(name:, email:, password:)
    page.driver.post users_path, {
      user: {
        name: name,
        email: email,
        password: password,
        password_confirmation: password
      }
    }.merge(bot_prevention_params)
  end

  def follow_redirect_if_present
    location = page.driver.response&.headers&.[]("Location")
    visit location if location.present?
  end

  def combined_page_content
    [ page.text, page.driver.response&.body ].compact.join("\n")
  end
end

World(TestHelpers)
