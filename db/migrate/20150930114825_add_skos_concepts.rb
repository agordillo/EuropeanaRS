class AddSkosConcepts < ActiveRecord::Migration
  def change
    add_column :los, :europeana_skos_concept, :string
  end
end
