# Set up Recommender System settings
# Store some variables in configuration to speed things up
# Config accesible in EuropeanaRS::Application::config

Rails.application.configure do
  
  # Default database to be used by the RS
  config.database = {}
  config.database[:default] = "EuropeanaRS"
  config.database[:europeana] = {}

  if config.APP_CONFIG["database"]
    config.database[:default] = config.APP_CONFIG["database"]["default"] if config.APP_CONFIG["database"]["default"]
    config.database[:europeana] = config.APP_CONFIG["database"]["europeana"].recursive_symbolize_keys if config.APP_CONFIG["database"]["europeana"].is_a? Hash
  end
  config.database[:europeana] = {:max_preselection_size => 100, :default_query => {}}.merge(config.database[:europeana])

  #EuropeanaRS API
  config.api = {}
  config.api[:require_key] = true

  if config.APP_CONFIG["europeanars_api"]
    if config.APP_CONFIG["europeanars_api"]["require_key"]
      config.api[:require_key] = (config.APP_CONFIG["europeanars_api"]["require_key"]!="false")
    end
  end

  #Default weights
  weights = {}
  weights[:default_rs] = {}
  weights[:default_los] = {}
  weights[:default_us] = {}
  weights[:popularity] = {}

  if config.APP_CONFIG["weights"]
    weights[:default_rs] = config.APP_CONFIG["weights"]["default_rs"].recursive_symbolize_keys if config.APP_CONFIG["weights"]["default_rs"]
    weights[:default_los] = config.APP_CONFIG["weights"]["default_los"].recursive_symbolize_keys if config.APP_CONFIG["weights"]["default_los"]
    weights[:default_us] = config.APP_CONFIG["weights"]["default_us"].recursive_symbolize_keys if config.APP_CONFIG["weights"]["default_us"]
    weights[:popularity] = config.APP_CONFIG["weights"]["popularity"].recursive_symbolize_keys if config.APP_CONFIG["weights"]["popularity"]
  end

  weights[:default_rs] = RecommenderSystem.defaultRSWeights.merge(weights[:default_rs])
  weights[:default_los] = RecommenderSystem.defaultLoSWeights.merge(weights[:default_los])
  weights[:default_us] = RecommenderSystem.defaultUSWeights.merge(weights[:default_us])
  weights[:popularity] = RecommenderSystem.defaultPopularityWeights.merge(weights[:popularity])

  config.weights = weights


  #Default filters
  filters = {}
  filters[:default_rs] = {}
  filters[:default_los] = {}
  filters[:default_us] = {}

  if config.APP_CONFIG["filters"]
    filters[:default_rs] = config.APP_CONFIG["filters"]["default_rs"].recursive_symbolize_keys if config.APP_CONFIG["filters"]["default_rs"]
    filters[:default_los] = config.APP_CONFIG["filters"]["default_los"].recursive_symbolize_keys if config.APP_CONFIG["filters"]["default_los"]
    filters[:default_us] = config.APP_CONFIG["filters"]["default_us"].recursive_symbolize_keys if config.APP_CONFIG["filters"]["default_us"]
  end

  filters[:default_rs] = RecommenderSystem.defaultRSFilters.merge(filters[:default_rs])
  filters[:default_los] = RecommenderSystem.defaultLoSFilters.merge(filters[:default_los])
  filters[:default_us] = RecommenderSystem.defaultUSFilters.merge(filters[:default_us])

  config.filters = filters

  
  #Search Engine
  config.max_matches = ThinkingSphinx::Configuration.instance.settings["max_matches"] || 10000
  config.max_preselection_size = (config.APP_CONFIG["max_preselection_size"].is_a?(Numeric) ? config.APP_CONFIG["max_preselection_size"] : 1000)
  config.max_preselection_size = [config.max_matches,config.max_preselection_size].min

  #RS: internal settings
  config.max_user_los = (config.APP_CONFIG["max_user_los"].is_a?(Numeric) ? config.APP_CONFIG["max_user_los"] : 5)

  #Permited params for the EuropeanaRS API
  permitedParamsLo = [:title, :description, :language, :year, :repository, :id_repository, :url, :thumbnail_url]
  permitedParamsUser = [:language, los: permitedParamsLo]
  permitedParamsUserFields = permitedParamsUser.map{|k| k.is_a?(Hash) ? k.keys.first : k}
  permitedParamsGeneralWeights = [:los_score, :us_score, :quality_score, :popularity_score]
  permitedParamsEuropeana = [:preselection_size, query: [:skos_concept, :type, :year_range]]
  permitedParamsSettings = [:database, :preselection_size, :preselection_filter_languages, europeana: permitedParamsEuropeana, rs_weights: permitedParamsGeneralWeights , los_weights: permitedParamsLo, us_weights: permitedParamsUserFields, rs_filters: permitedParamsGeneralWeights, los_filters: permitedParamsLo, us_filters: permitedParamsUserFields]
  config.api[:permitedParams] = [:api_key, :private_key, :n, :query, lo_profile: permitedParamsLo, user_profile: permitedParamsUser, settings: permitedParamsSettings]
  permitedParamsFeedback = [:action, lo_profile: permitedParamsLo]
  config.api[:permitedParamsUsers] = [:user_id, user_profile: permitedParamsUser, feedback: permitedParamsFeedback]
  config.api[:permitedParamsLos] = [:id_europeana, lo_profile: permitedParamsLo]

  #Settings for speed up TF-IDF calculations
  config.max_text_length = (config.APP_CONFIG["max_text_length"].is_a?(Numeric) ? config.APP_CONFIG["max_text_length"] : 60)
  config.repository_total_entries = Lo.count
  
  #Keep words in the configuration
  words = {}
  Word.where("occurrences > ?",1).first(5000000).each do |word|
    words[word.value] = word.occurrences
  end
  config.words = words

  #Stop words (readed from the file stopwords.yml)
  config.stopwords = File.read("config/stopwords.yml").split(",").map{|s| s.gsub("\n","").gsub("\"","") } rescue []
end


