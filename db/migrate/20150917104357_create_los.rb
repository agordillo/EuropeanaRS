class CreateLos < ActiveRecord::Migration
  def change
    create_table :los do |t|
      t.text :europeana_metadata
      t.text :id_europeana
      t.text :url
      t.text :title
      t.text :description
      t.string :language
      t.text :thumbnail_url
      t.integer :year
      t.integer :metadata_quality

      t.timestamps null: false
    end
  end
end
