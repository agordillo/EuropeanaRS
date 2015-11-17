class Utils

  #################
  # Languages Utils
  #################

  def self.valid_locale?(locale)
    !locale.blank? and I18n.available_locales.map(&:to_s).include? locale
  end

  def self.getAllLanguages
    ["bg", "de", "en", "es", "et", "fr", "lb", "lv", "nl", "pl", "pt", "ro", "ru", "sr"]
  end

  #Translate ISO 639-1 codes to readable language names
  def self.getReadableLanguage(lanCode="")
    I18n.t("languages." + lanCode, :default => lanCode)
  end

  def self.getCountryFromLanguage(lanCode="")
    case lanCode.downcase
    when "bg"
      "Bulgaria"
    when "cy"
      "Wales"
    when "de"
      "Germany"
    when "en"
      "England"
    when "es"
      "Spain"
    when "et"
      "Estonia"
    when "fr"
      "France"
    when "it"
      "Italy"
    when "lb"
      "Luxembourg"
    when "lv"
      "Latvia"
    when "nl"
      "Netherlands"
    when "pl"
      "Poland"
    when "pt"
      "Portugal"
    when "ro"
      "Romania"
    when "ru"
      "Russia"
    when "sr"
      "Serbia"
    else
      lanCode.downcase
    end
  end

  def self.getLanguageFromCountry(country="")
    getAllLanguages.each do |lanCode|
      return lanCode if country.downcase==Utils.getCountryFromLanguage(lanCode).downcase
    end
    return I18n.default_locale.to_s
  end


  def self.getResourceTypes
    EuropeanaRS::Application::config.settings[:resource_types]
  end

  def self.getAllResourceTypes
    ["TEXT","VIDEO","SOUND","IMAGE","3D"]
  end

  def self.getReadableResourceType(type="")
    I18n.t("resource_types." + type.downcase, :default => type)
  end

  def self.getRandom(options={})
    options[:n] = 20 unless options[:n].is_a? Integer

    # Search random resources using the search engine
    searchOptions = {}
    searchOptions[:n] = [options[:n],EuropeanaRS::Application::config.settings[:europeanars_database][:max_preselection_size]].min
    searchOptions[:models] = [Lo]
    searchOptions[:order] = "random"
    searchOptions[:ids_to_avoid] = options[:ids_to_avoid] unless options[:ids_to_avoid].blank?
    searchOptions[:europeana_ids_to_avoid] = options[:europeana_ids_to_avoid] unless options[:europeana_ids_to_avoid].blank?

    los = Search.search(searchOptions)

    #Convert LOs to LO profiles
    return los.map{|lo| lo.profile}
  end
end
