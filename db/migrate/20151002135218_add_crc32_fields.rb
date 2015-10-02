class AddCrc32Fields < ActiveRecord::Migration
  def up
    add_column :los, :resource_type_crc32, :bigint
    add_column :los, :language_crc32, :bigint
    add_column :los, :europeana_collection_name_crc32, :bigint
    add_column :los, :country_crc32, :bigint
    add_column :los, :europeana_skos_concept_crc32, :bigint
  end

  def down
    remove_column :los, :resource_type_crc32
    remove_column :los, :language_crc32
    remove_column :los, :europeana_collection_name_crc32
    remove_column :los, :country_crc32
    remove_column :los, :europeana_skos_concept_crc32
  end
end
