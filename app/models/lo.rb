class Lo < ActiveRecord::Base
  acts_as_taggable

  validates :id_europeana, :presence => true, :uniqueness => true
  validates :europeana_metadata, :presence => true
  validates :url, :presence => true, :uniqueness => true
  validates :title, :presence => true

  before_validation :parseMetadata

  def parseMetadata
    europeanaItem = JSON.parse(self.europeana_metadata) rescue nil
    return if europeanaItem.nil?

    begin
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
    rescue => e
    end
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

    if country.nil?
      case self.language
        when "bg"
          country = "Bulgaria"
        when "cy"
          country = "Wales"
        when "de"
          country = "Germany"
        when "en"
          country = "England"
        when "es"
          country = "Spain"
        when "et"
          country = "Estonia"
        when "fr"
          country = "France"
        when "it"
          country = "Italy"
        when "lb"
          country = "Luxembourg"
        when "lv"
          country = "Latvia"
        when "nl"
          country = "Netherlands"
        when "pl"
          country = "Poland"
        when "pt"
          country = "Portugal"
        when "ro"
          country = "Romania"
        when "ru"
          country = "Russia"
        when "sr"
          country = "Serbia"
        else
      end
    end

    country
  end

end