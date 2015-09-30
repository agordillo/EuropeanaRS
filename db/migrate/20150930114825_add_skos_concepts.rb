class AddSkosConcepts < ActiveRecord::Migration
  def up
    add_column :los, :europeana_skos_concept, :string
  end

  def down
    remove_column :los, :europeana_skos_concept
  end
end
