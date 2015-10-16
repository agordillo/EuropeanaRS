# Set up Recommender System settings
# Config accesible in EuropeanaRS::Application::config

Rails.application.configure do
  #Default weights
  weights = {}
  weights[:default_rs] = {}
  weights[:default_los] = {}
  weights[:default_us] = {}

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

  #Store some variables in configuration to speed things up
  config.maxPreselectionSize = (config.APP_CONFIG["max_preselection_size"].is_a?(Numeric) ? config.APP_CONFIG["max_preselection_size"] : 1000)
  config.maxTextLength = (config.APP_CONFIG["max_text_length"].is_a?(Numeric) ? config.APP_CONFIG["max_text_length"] : 60)
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


