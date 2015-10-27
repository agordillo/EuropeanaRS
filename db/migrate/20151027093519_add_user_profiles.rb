class AddUserProfiles < ActiveRecord::Migration
  def change
    create_table :user_profiles do |t|
      t.integer :user_id
      t.integer :app_id

      t.integer :id_app

      t.string :language
      t.string :settings
      t.text :tags
      
      t.timestamps null: false
    end

    create_table 'lo_profiles_user_profiles', :id => false do |t|
      t.column :user_profile_id, :integer
      t.column :lo_profile_id, :integer
    end
  end
end
