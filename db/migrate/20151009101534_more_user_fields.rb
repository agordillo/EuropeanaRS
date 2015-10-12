class MoreUserFields < ActiveRecord::Migration
  def up
  	add_column :users, :settings, :text
    add_column :users, :language, :string
  end

  def down
  	# remove_column :users, :settings
    remove_column :users, :language
  end
end
