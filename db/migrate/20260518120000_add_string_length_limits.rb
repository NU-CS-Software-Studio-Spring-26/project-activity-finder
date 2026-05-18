class AddStringLengthLimits < ActiveRecord::Migration[8.1]
  def change
    change_column :activities, :title, :string, limit: Activity::TITLE_MAX_LENGTH
    change_column :activities, :city, :string, limit: Activity::CITY_MAX_LENGTH
    change_column :activities, :category, :string, limit: Activity::CATEGORY_MAX_LENGTH
    change_column :activities, :location, :string, limit: Activity::LOCATION_MAX_LENGTH

    change_column :users, :name, :string, limit: User::NAME_MAX_LENGTH
    change_column :users, :email, :string, limit: User::EMAIL_MAX_LENGTH
  end
end
