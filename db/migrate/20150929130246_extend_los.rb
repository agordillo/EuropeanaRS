class ExtendLos < ActiveRecord::Migration
  def change
    add_column :los, :full_url, :text
    add_column :los, :europeana_collection_name, :string
    add_column :los, :country, :string
    add_column :los, :resource_type, :string
  end
end
