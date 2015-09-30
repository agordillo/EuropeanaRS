class ExtendLos < ActiveRecord::Migration
  def up
    add_column :los, :full_url, :text
    add_column :los, :europeana_collection_name, :string
    add_column :los, :country, :string
    add_column :los, :resource_type, :string
  end

  def down
    remove_column :los, :full_url
    remove_column :los, :europeana_collection_name
    remove_column :los, :country
    remove_column :los, :resource_type
  end
end
