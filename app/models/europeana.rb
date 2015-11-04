# encoding: utf-8

###############
# Class with utils for handling metadata records from Europeana
###############

class Europeana

  #####################
  # EuropeanaRS methods
  #####################

  def self.createLoFromItem(europeanaItem)
    lo = Lo.new
    lo.europeana_metadata = europeanaItem.to_json rescue nil
    lo.save
    lo
  end

  def self.createLoProfileFromItem(europeanaItem)
    LoProfile.fromLoProfile(Europeana.createVirtualLoProfileFromItem(europeanaItem))
  end

  def self.createVirtualLoProfileFromItem(europeanaItem,options={})
    lo_profile = {}

    lo_profile[:repository] = "Europeana"
    lo_profile[:id_repository] = europeanaItem["id"]

    lo_profile[:resource_type] = europeanaItem["type"]
    lo_profile[:title] = europeanaItem["title"].first unless europeanaItem["title"].nil?
    lo_profile[:description] = europeanaItem["dcDescription"].first unless europeanaItem["dcDescription"].nil?
    if !europeanaItem["dcLanguage"].nil?
      lo_profile[:language] = europeanaItem["dcLanguage"].first
    elsif !europeanaItem["language"].nil?
      lo_profile[:language] = europeanaItem["language"].first
    end
    lo_profile[:year] = europeanaItem["year"].first.to_i unless europeanaItem["year"].nil?
    lo_profile[:quality] = europeanaItem["europeanaCompleteness"]
    lo_profile[:popularity] = 0

    lo_profile[:url] = europeanaItem["guid"]
    lo_profile[:thumbnail_url] = europeanaItem["edmPreview"].first unless europeanaItem["edmPreview"].nil?

    unless options[:external]
      lo_profile[:external] = true
    end

    lo_profile
  end

  def self.createLoProfileFromMyEuropeanaItem(europeanaItem)
    Europeana::MyEuropeana.createLoProfileFromMyEuropeanaItem(europeanaItem)
  end


  #####################
  # Utils
  #####################

  def self.inferCountryFromLanguage(language,europeanaCollectionName=nil)
    #Currently Europeana does not provide information about the country.
    #So, we try to infer the country from the collection or language of the item.

    country = nil

    #First try to infer by the Europeana Collection name
    case europeanaCollectionName
    when "9200385_Ag_EU_TEL_a0644_Newspapers_Wales"
      country = "Wales"
    else
    end

    country = Utils.getCountryFromLanguage(language) if country.nil?

    country
  end

  def self.getResourceTypes
    ["TEXT","VIDEO","SOUND","IMAGE","3D"]
  end

end