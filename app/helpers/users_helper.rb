module UsersHelper
  AVATAR_PIXELS = { sm: 36, md: 48, lg: 80, xl: 112 }.freeze

  def user_avatar_initial(user)
    user.avatar_initial
  end

  def user_avatar_pixels(size)
    AVATAR_PIXELS[size.to_sym] || AVATAR_PIXELS[:md]
  end
end
