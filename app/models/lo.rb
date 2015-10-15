class Lo < ActiveRecord::Base
  attr_accessor :score

  has_and_belongs_to_many :users

  acts_as_taggable

  validates :id_europeana, :presence => true, :uniqueness => true
  validates :europeana_metadata, :presence => true
  validates :url, :presence => true, :uniqueness => true
  validates :title, :presence => true

  before_validation :parseMetadata
  before_validation :crc32_fields

  def profile
    lo_profile = {}
    lo_profile[:title] = self.title
    lo_profile[:description] = self.description
    lo_profile[:language] = self.language
    lo_profile[:year] = self.year

    lo_profile
  end

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
    self.country = self.inferCountry #this should be done after assign the language and the europeana collection name

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

  def inferCountry
    #Currently Europeana does not provide information about the country.
    #So, we try to infer the country from the collection or language of the item.

    country = nil

    #First try to infer by the Europeana Collection name
    case self.europeana_collection_name
    when "9200385_Ag_EU_TEL_a0644_Newspapers_Wales"
      country = "Wales"
    else
    end

    country = Europeana.getCountryFromLanguage(self.language) if country.nil?

    country
  end

  def readable_language
    Europeana.getReadableLanguage(self.language)
  end

end