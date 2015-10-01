ThinkingSphinx::Index.define :lo, :with => :active_record do
  # fields
  indexes title
  indexes description

  # attributes
  has created_at, updated_at
  has year
  has language
end