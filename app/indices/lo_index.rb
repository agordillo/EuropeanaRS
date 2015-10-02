ThinkingSphinx::Index.define :lo, :with => :active_record do
  # fields
  indexes title
  indexes description

  # attributes
  has id, :as => :lo_id
  has created_at, updated_at
  has year
  has language
  has metadata_quality
end