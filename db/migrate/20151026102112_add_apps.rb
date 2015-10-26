class AddApps < ActiveRecord::Migration
  def change
    create_table :apps do |t|
      t.integer :user_id
      t.string :name
      t.string :app_key
      t.string :app_secret
      t.timestamps null: false
    end
  end
end