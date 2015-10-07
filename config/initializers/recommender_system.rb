# Set up Recommender System settings

Rails.application.configure do
  #Default weights
  weights = {}
  weights[:default_rs_weights] = {}
  weights[:default_los_weights] = {}
  weights[:default_us_weights] = {}

  if config.APP_CONFIG["weights"]
    weights[:default_rs_weights] = config.APP_CONFIG["default_rs_weights"] if config.APP_CONFIG["default_rs_weights"]
    weights[:default_los_weights] = config.APP_CONFIG["default_los_weights"] if config.APP_CONFIG["default_los_weights"]
    weights[:default_us_weights] = config.APP_CONFIG["default_us_weights"] if config.APP_CONFIG["default_us_weights"]
  end

  weights[:default_rs_weights] = RecommenderSystem.defaultRSWeights.merge(weights[:default_rs_weights])
  weights[:default_los_weights] = RecommenderSystem.defaultLoSWeights.merge(weights[:default_los_weights])
  weights[:default_us_weights] = RecommenderSystem.defaultUSWeights.merge(weights[:default_us_weights])

  config.weights = weights

  #Store some variables in configuration to speed things up
  config.repository_total_entries = Lo.count
  config.maxTextLength = (config.APP_CONFIG["max_text_length"].is_a?(Numeric) ? config.APP_CONFIG["max_text_length"] : 60)

  #Keep words in the configuration
  words = {}
  Word.where("occurrences > ?",1).first(5000000).each do |word|
    words[word.value] = word.occurrences
  end
  config.words = words

  #Stop words (readed from the file stopwords.yml)
  config.stopwords = File.read("config/stopwords.yml").split(",").map{|s| s.gsub("\n","").gsub("\"","") } rescue []
end


