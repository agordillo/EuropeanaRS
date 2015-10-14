class MoreUserFields < ActiveRecord::Migration
  def up
    add_column :users, :settings, :text
    add_column :users, :language, :string
    add_column :users, :ui_language, :string
  end

  def down
    remove_column :users, :settings
    remove_column :users, :language
    remove_column :users, :ui_language
  end
end
