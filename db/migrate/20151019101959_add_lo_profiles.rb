class AddLoProfiles < ActiveRecord::Migration
  def change
    create_table :lo_profiles do |t|
      t.integer :lo_id

      t.string :repository
      t.text :id_repository

      t.text :title
      t.text :description
      t.string :language
      t.integer :year

      t.integer :quality, :default => 0
      t.integer :popularity, :default => 0

      t.text :url
      t.text :thumbnail_url

      t.timestamps null: false
    end

    create_table 'lo_profiles_users', :id => false do |t|
      t.column :user_id, :integer
      t.column :lo_profile_id, :integer
    end
  end
end