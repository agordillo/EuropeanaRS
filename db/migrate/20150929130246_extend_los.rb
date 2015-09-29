class ExtendLos < ActiveRecord::Migration
  def up
    add_column :los, :full_url, :text
    add_column :los, :europeana_collection_name, :string
    add_column :los, :country, :string
  end

  def down
    remove_column :los, :full_url
    remove_column :los, :europeana_collection_name
    remove_column :los, :country
  end
end
