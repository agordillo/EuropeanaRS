ThinkingSphinx::Index.define :lo, :with => :active_record do
  # fields
  indexes title
  indexes description

  # attributes
  has id, :as => :lo_id
  has created_at, updated_at
  has year
  has metadata_quality
  has popularity

  has resource_type_crc32, :as => :resource_type
  has language_crc32, :as => :language
  has europeana_collection_name_crc32, :as => :europeana_collection_name
  has country_crc32, :as => :country
  has europeana_skos_concept_crc32, :as => :europeana_skos_concept
end