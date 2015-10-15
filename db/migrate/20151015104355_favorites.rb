class Favorites < ActiveRecord::Migration
  def change
    create_table 'los_users', :id => false do |t|
      t.column :user_id, :integer
      t.column :lo_id, :integer
    end
  end
end
