class CreateLos < ActiveRecord::Migration
  def change
    create_table :los do |t|
      t.timestamps null: false
      t.text :europeana_metadata
      t.text :title
      t.text :description
    end
  end
end
