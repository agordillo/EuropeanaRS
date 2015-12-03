# Set up Recommender System settings
# Store some variables in configuration to speed things up
# Config accesible in EuropeanaRS::Application::config

Rails.application.configure do
  
  #Europeana credentials
  config.europeana = {}
  config.europeana = config.APP_CONFIG["europeana"].parse_for_rs unless config.APP_CONFIG["europeana"].blank?

  #EuropeanaRS fixed settings
  config.settings = {}
  config.settings = config.APP_CONFIG["settings"].parse_for_rs unless config.APP_CONFIG["settings"].blank?
  config.settings = {:resource_types => Utils.getAllResourceTypes, :max_text_length => 50, :max_user_los => 2, :europeanars_database => {:max_preselection_size => 500}, :europeana_database => {:preselection_size => 500}}.recursive_merge(config.settings)
  config.settings[:resource_types] = config.settings[:resource_types] & Utils.getAllResourceTypes

  #Default settings to use in EuropeanaRS
  config.default_settings = {}
  config.default_settings = config.APP_CONFIG["default_settings"].parse_for_rs unless config.APP_CONFIG["default_settings"].blank?
  config.default_settings = {:database => "EuropeanaRS", :preselection_filter_resource_type => "true", :preselection_filter_languages => "true", :europeanars_database => {:preselection_size => 500}, :europeana_database => {:preselection_size => 500, :query => {}}}.recursive_merge(config.default_settings)

  #EuropeanaRS API
  config.api = {}
  config.api = config.APP_CONFIG["europeanars_api"].parse_for_rs unless config.APP_CONFIG["europeanars_api"].blank?
  config.api = {:require_key => true}.recursive_merge(config.api)

  #Default weights
  weights = {}
  weights[:default_rs] = RecommenderSystem.defaultRSWeights
  weights[:default_los] = RecommenderSystem.defaultLoSWeights
  weights[:default_us] = RecommenderSystem.defaultUSWeights
  weights[:popularity] = RecommenderSystem.defaultPopularityWeights

  if config.APP_CONFIG["weights"]
    weights[:default_rs] = weights[:default_rs].recursive_merge(config.APP_CONFIG["weights"]["default_rs"].parse_for_rs) if config.APP_CONFIG["weights"]["default_rs"]
    weights[:default_los] = weights[:default_los].recursive_merge(config.APP_CONFIG["weights"]["default_los"].parse_for_rs) if config.APP_CONFIG["weights"]["default_los"]
    weights[:default_us] = weights[:default_us].recursive_merge(config.APP_CONFIG["weights"]["default_us"].parse_for_rs) if config.APP_CONFIG["weights"]["default_us"]
    weights[:popularity] = weights[:popularity].recursive_merge(config.APP_CONFIG["weights"]["popularity"].parse_for_rs) if config.APP_CONFIG["weights"]["popularity"]
  end

  config.weights = weights


  #Default filters
  filters = {}
  filters[:default_rs] = RecommenderSystem.defaultRSFilters
  filters[:default_los] = RecommenderSystem.defaultLoSFilters
  filters[:default_us] = RecommenderSystem.defaultUSFilters

  if config.APP_CONFIG["filters"]
    filters[:default_rs] = filters[:default_rs].recursive_merge(config.APP_CONFIG["filters"]["default_rs"].parse_for_rs)if config.APP_CONFIG["filters"]["default_rs"]
    filters[:default_los] = filters[:default_los].recursive_merge(config.APP_CONFIG["filters"]["default_los"].parse_for_rs)if config.APP_CONFIG["filters"]["default_los"]
    filters[:default_us] = filters[:default_us].recursive_merge(config.APP_CONFIG["filters"]["default_us"].parse_for_rs)if config.APP_CONFIG["filters"]["default_us"]
  end

  config.filters = filters

  
  #Search Engine
  config.max_matches = ThinkingSphinx::Configuration.instance.settings["max_matches"] || 10000
  config.settings[:europeanars_database][:max_preselection_size] = [config.max_matches,config.settings[:europeanars_database][:max_preselection_size]].min

  #RS: internal settings
  config.max_user_los = (config.settings[:max_user_los].is_a?(Numeric) ? config.settings[:max_user_los] : 2)

  #Permited params for the EuropeanaRS API
  permitedParamsLo = [:resource_type, :title, :description, :language, :year, :repository, :id_repository, :url, :thumbnail_url]
  permitedParamsUser = [:language, los: permitedParamsLo]
  permitedParamsUserFields = permitedParamsUser.map{|k| k.is_a?(Hash) ? k.keys.first : k}
  permitedParamsGeneralWeights = [:los_score, :us_score, :quality_score, :popularity_score]
  permitedParamsEuropeanaRSDatabase = [:preselection_size]
  permitedParamsEuropeanaDatabase = [:preselection_size, query: [:skos_concept, :type, :year_range]]
  permitedParamsSettings = [:database, :query, :preselection_filter_resource_type, :preselection_filter_languages, europeanars_database: permitedParamsEuropeanaRSDatabase, europeana_database: permitedParamsEuropeanaDatabase, rs_weights: permitedParamsGeneralWeights , los_weights: permitedParamsLo, us_weights: permitedParamsUserFields, rs_filters: permitedParamsGeneralWeights, los_filters: permitedParamsLo, us_filters: permitedParamsUserFields]
  config.api[:permitedParams] = [:api_key, :private_key, :n, :query, lo_profile: permitedParamsLo, user_profile: permitedParamsUser, settings: permitedParamsSettings]
  permitedParamsFeedback = [:action, lo_profile: permitedParamsLo]
  config.api[:permitedParamsUsers] = [:user_id, user_profile: permitedParamsUser, feedback: permitedParamsFeedback]
  config.api[:permitedParamsLos] = [:id_europeana, lo_profile: permitedParamsLo]

  #Settings for speed up TF-IDF calculations
  config.max_text_length = (config.settings[:max_text_length].is_a?(Numeric) ? config.settings[:max_text_length] : 50)
  config.repository_total_entries = [Lo.count,1].max
  
  #Keep words in the configuration
  words = {}
  if ActiveRecord::Base.connection.table_exists?('words')
    Word.where("occurrences > ?",5).first(5000000).each do |word|
      words[word.value] = [word.occurrences,config.repository_total_entries-1].min
    end
  end
  config.words = words
end


