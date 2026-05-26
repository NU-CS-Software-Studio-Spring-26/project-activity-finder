class AddVisibilityAndShareTokenToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :visibility, :string, default: "public", null: false
    add_column :activities, :share_token, :string
    add_index :activities, :share_token, unique: true
  end
end
