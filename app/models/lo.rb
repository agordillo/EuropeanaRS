class Lo < ActiveRecord::Base
  has_and_belongs_to_many :users

  acts_as_taggable

  before_validation :parseMetadata
  before_validation :crc32_fields

  validates :id_europeana, :presence => true, :uniqueness => true
  validates :europeana_metadata, :presence => true
  validates :url, :presence => true, :uniqueness => true
  validates :title, :presence => true


  #################
  # Getters
  #################

  def profile(options={})
    LoProfile.toProfile(self,options)
  end

  def readable_language
    Europeana.getReadableLanguage(self.language)
  end

  #################
  # Lo methods
  #################
  def update_visit_count
    self.update(:visit_count => self.visit_count+1)
  end

  def update_like_count
    likes = self.users.length
    self.update(:like_count => likes) if self.like_count != likes
  end

  private 

  def parseMetadata
    europeanaItem = JSON.parse(self.europeana_metadata) rescue nil
    return if europeanaItem.nil?

    self.id_europeana = europeanaItem["id"]
    self.url = europeanaItem["guid"]
    self.full_url = europeanaItem["edmIsShownAt"].first unless europeanaItem["edmIsShownAt"].nil?
    self.title = europeanaItem["title"].first unless europeanaItem["title"].nil?
    self.description = europeanaItem["dcDescription"].first unless europeanaItem["dcDescription"].nil?
    self.resource_type = europeanaItem["type"]

    if !europeanaItem["dcLanguage"].nil?
      self.language = europeanaItem["dcLanguage"].first
    elsif !europeanaItem["language"].nil?
      self.language = europeanaItem["language"].first
    end

    self.thumbnail_url = europeanaItem["edmPreview"].first unless europeanaItem["edmPreview"].nil?
    self.year = europeanaItem["year"].first.to_i unless europeanaItem["year"].nil?
    self.metadata_quality = europeanaItem["europeanaCompleteness"]
    self.europeana_collection_name = europeanaItem["europeanaCollectionName"].first unless europeanaItem["europeanaCollectionName"].nil?
    self.country = Europeana.inferCountryFromLanguage(self.language,self.europeana_collection_name)

    #Concept
    self.europeana_skos_concept = europeanaItem["edmConcept"].first unless europeanaItem["edmConcept"].nil?

    #Tags
    unless europeanaItem["edmConceptPrefLabelLangAware"].nil? or europeanaItem["edmConceptPrefLabelLangAware"]["en"].nil?
      if europeanaItem["edmConceptPrefLabelLangAware"]["en"].is_a? Array
        self.tag_list = europeanaItem["edmConceptPrefLabelLangAware"]["en"]
      end
    end
  end

  def crc32_fields
    self.resource_type_crc32 = self.resource_type.to_crc32 unless self.resource_type.nil?
    self.language_crc32 = self.language.to_crc32 unless self.language.nil?
    self.europeana_collection_name_crc32 = self.europeana_collection_name.to_crc32 unless self.europeana_collection_name.nil?
    self.country_crc32 = self.country.to_crc32 unless self.country.nil?
    self.europeana_skos_concept_crc32 = self.europeana_skos_concept.to_crc32 unless self.europeana_skos_concept.nil?
  end

end