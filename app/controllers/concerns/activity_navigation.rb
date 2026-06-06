module ActivityNavigation
  extend ActiveSupport::Concern

  private

  def from_profile?
    params[:from] == "profile"
  end

  def safe_profile_return_path?(path)
    path = normalized_return_path(path)
    path.present? &&
      path.start_with?("/") &&
      !path.start_with?("//") &&
      !path.include?("://") &&
      path.match?(%r{\A/users/\d+(\?.*)?\z})
  end

  def normalized_return_path(path)
    path = path.to_s.strip
    return path if path.blank?
    return path unless path.match?(%r{\Ahttps?://}i)

    uri = URI.parse(path)
    normalized = uri.path.to_s
    normalized = "#{normalized}?#{uri.query}" if uri.query.present?
    normalized
  rescue URI::InvalidURIError
    nil
  end

  def profile_return_path
    path = normalized_return_path(params[:return_to])
    return path if safe_profile_return_path?(path)

    user_path(current_user)
  end

  def activity_list_return_path
    if from_profile?
      profile_return_path
    elsif safe_activity_list_return_path?(params[:return_to])
      params[:return_to].to_s
    else
      root_path
    end
  end

  def safe_activity_list_return_path?(path)
    path = path.to_s
    path.present? &&
      path.start_with?("/") &&
      !path.start_with?("//") &&
      !path.include?("://") &&
      path.match?(%r{\A/(?:activities(?:\?.*)?)?(?:\?.*)?\z})
  end

  def show_activity_management?
    from_profile? && (@activity.user == current_user || current_user.admin?)
  end

  def require_profile_management_context!
    return if current_user.admin?
    return if from_profile?

    redirect_to activity_path(@activity), alert: "You can only edit or delete activities from your profile."
  end

  def activity_source_query_params
    return {} unless from_profile?

    { from: "profile", return_to: params[:return_to].presence || profile_return_path }
  end
end
