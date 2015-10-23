# encoding: utf-8

###############
# EuropeanaRS Recommender System
###############

class RecommenderSystem

  # Usage example: RecommenderSystem.suggestions({:n=>10})
  def self.suggestions(options={})

    # Step 0: Initialize all variables
    options = prepareOptions(options)

    #Step 1: Preselection
    preSelectionLOs = getPreselection(options)

    #Step 2: Scoring
    rankedLOs = calculateScore(preSelectionLOs,options)

    #Step 3: Filtering
    filteredLOs = filter(rankedLOs,options)

    #Step 4: Sorting
    sortedLOs = filteredLOs.sort { |a,b|  b[:score] <=> a[:score] }

    #Step 5: Delivering
    return sortedLOs.first(options[:n])
  end

  # Step 0: Initialize all variables
  def self.prepareOptions(options={})
    options = {:n => 10, :user_profile => {}, :lo_profile => {}, :settings => {}}.merge(options)
    options[:n] = options[:n].to_i
    options[:user_profile][:los] = options[:user_profile][:los].first(EuropeanaRS::Application::config.max_user_los) unless options[:user_profile][:los].blank?
    options
  end

  #Step 1: Preselection
  def self.getPreselection(options={})
    preSelection = []

    # Search resources using the search engine
    searchOptions = {};

    searchOptions[:n] = options[:settings][:preselection_size] || EuropeanaRS::Application::config.max_preselection_size
    searchOptions[:n] = [EuropeanaRS::Application::config.max_matches,searchOptions[:n]].min
    searchOptions[:models] = [Lo]
    searchOptions[:order] = "random"

    # Define some filters for the preselection
    
    # A. Query
    searchOptions[:query] = options[:settings][:query] unless options[:settings][:query].blank?
    
    # B. Language.
    unless options[:settings][:preselection_filter_languages] == false
      # B. Multilanguage approach.
      preselectionLanguages = []
      if options[:lo_profile][:language]
        preselectionLanguages << options[:lo_profile][:language]
      end
      if options[:user_profile][:language]
        preselectionLanguages << options[:user_profile][:language]
      end
      if options[:user_profile][:los]
        preselectionLanguages += options[:user_profile][:los].map{|lo| lo[:language]}.compact
      end
      preselectionLanguages.uniq!
      preselectionLanguages = preselectionLanguages & Europeana.getAllLanguages

      searchOptions[:languages] = preselectionLanguages unless preselectionLanguages.blank?

      # B. (Alternative). Single language approach
      # preselectionLanguage = nil
      # if options[:lo_profile][:language]
      #   preselectionLanguage = options[:lo_profile][:language]
      # elsif options[:user_profile][:language]
      #   preselectionLanguage = options[:user_profile][:language]
      # end
      # searchOptions[:languages] = [preselectionLanguage] unless preselectionLanguage.nil?
    end

    #C. Repeated resources.
    if options[:lo_profile][:id_europeana]
      searchOptions[:europeana_ids_to_avoid] = [options[:lo_profile][:id_europeana]]
    end
    
    # First attempt for the preselection
    preSelection = Search.search(searchOptions)

    if preSelection.blank?
      #Try with other search options
      searchFlag = false

      # Disable language filter
      unless searchOptions[:languages].blank?
        searchOptions.delete(:languages)
        preSelection = Search.search(searchOptions)
        searchFlag = true
      end

      # Disable query filter
      if !searchFlag or preSelection.blank?
        unless searchOptions[:query].blank?
          searchOptions.delete(:query)
          preSelection = Search.search(searchOptions)
          searchFlag = true
        end
      end
    end

    #Convert LOs to profile LOs
    preSelection = preSelection.map{|lo| lo.profile({:external => options[:external]})}

    return preSelection
  end

  #Step 2: Scoring
  def self.calculateScore(preSelectionLOs,options)
    return preSelectionLOs if preSelectionLOs.blank?

    weights = RecommenderSystem.getRSWeights(options)
    weights_sum = 1
    options[:weights_los] = RecommenderSystem.getLoSWeights(options)
    options[:weights_us] = RecommenderSystem.getUSWeights(options)

    filters = RecommenderSystem.getRSFilters(options)

    if options[:lo_profile].blank?
      weights_sum = (weights_sum-weights[:los_score])
      weights[:los_score] = 0
      filters[:los_score] = 0
      options[:filtering_los] = false
    end
    if options[:user_profile].blank?
      weights_sum = (weights_sum-weights[:us_score])
      weights[:us_score] = 0
      filters[:us_score] = 0
      options[:filtering_us] = false
    end
    
    weights.each { |k, v| weights[k] = [1,v/weights_sum.to_f].min } if (weights_sum < 1 and weights_sum > 0)

    #Check if any individual filtering should be performed
    if options[:filtering_los].nil?
      options[:filters_los] = RecommenderSystem.getLoSFilters(options)
      options[:filtering_los] = options[:filters_los].map {|k,v| v}.sum > 0
    end
    if options[:filtering_us].nil?
      options[:filters_us] = RecommenderSystem.getUSFilters(options)
      options[:filtering_us] = options[:filters_us].map {|k,v| v}.sum > 0
    end

    calculateLoSimilarityScore = ((weights[:los_score]>0)||(filters[:los_score]>0)||options[:filtering_los])
    calculateUserSimilarityScore = ((weights[:us_score]>0)||(filters[:us_score]>0)||options[:filtering_us] )
    calculateQualityScore = ((weights[:quality_score]>0)||(filters[:quality_score]>0))
    calculatePopularityScore = ((weights[:popularity_score]>0)||(filters[:popularity_score]>0))

    preSelectionLOs.map{ |loProfile|
      los_score = calculateLoSimilarityScore ? RecommenderSystem.loProfileSimilarityScore(options[:lo_profile],loProfile,options) : 0
      (loProfile[:filtered]=true and next) if (calculateLoSimilarityScore and los_score < filters[:los_score])
      
      us_score = calculateUserSimilarityScore ? RecommenderSystem.userProfileSimilarityScore(options[:user_profile],loProfile,options) : 0
      (loProfile[:filtered]=true and next) if (calculateUserSimilarityScore and us_score < filters[:us_score])
      
      quality_score = calculateQualityScore ? RecommenderSystem.qualityScore(loProfile) : 0
      (loProfile[:filtered]=true and next) if (calculateQualityScore and quality_score < filters[:quality_score])
      
      popularity_score = calculatePopularityScore ? RecommenderSystem.popularityScore(loProfile) : 0
      (loProfile[:filtered]=true and next) if (calculatePopularityScore and popularity_score < filters[:popularity_score])

      loProfile[:score] = weights[:los_score] * los_score + weights[:us_score] * us_score + weights[:quality_score] * quality_score + weights[:popularity_score] * popularity_score
    }

    preSelectionLOs
  end

  #Step 3: Filtering
  #Filtered Learning Objects are marked with the lo[:filtered] key.
  def self.filter(rankedLOs,options)
    rankedLOs.select{|lo| lo[:filtered].nil? }
  end


  #######################
  ## Utils for Scoring the Learning Objects
  #######################

  #Learning Object Similarity Score, [0,1] scale
  def self.loProfileSimilarityScore(loProfileA,loProfileB,options={})
    weights = options[:weights_los] || RecommenderSystem.getLoSWeights(options)
    filters = options[:filtering_los]!=false ? (options[:filters_los] || RecommenderSystem.getLoSFilters(options)) : nil
    
    titleS = RecommenderSystem.getSemanticDistance(loProfileA[:title],loProfileB[:title])
    descriptionS = RecommenderSystem.getSemanticDistance(loProfileA[:description],loProfileB[:description])
    languageS = RecommenderSystem.getSemanticDistanceForCategoricalFields(loProfileA[:language],loProfileB[:language])
    yearS = RecommenderSystem.getSemanticDistanceForYears(loProfileA[:year],loProfileB[:year])

    return -1 if (!filters.blank? and (titleS < filters[:title] || descriptionS < filters[:description] || languageS < filters[:language] || yearS < filters[:year]))

    return weights[:title] * titleS + weights[:description] * descriptionS + weights[:language] * languageS + weights[:year] * yearS
  end

  #User profile Similarity Score, [0,1] scale
  def self.userProfileSimilarityScore(userProfile,loProfile,options={})
    weights = options[:weights_us] || RecommenderSystem.getUSWeights(options)
    filters = options[:filtering_us]!=false ? (options[:filters_us] || RecommenderSystem.getUSFilters(options)) : nil
    
    languageS = RecommenderSystem.getSemanticDistanceForCategoricalFields(userProfile[:language],loProfile[:language])

    losS = 0
    unless userProfile[:los].blank?
      userProfile[:los].each do |pastLoProfile|
        losS += RecommenderSystem.loProfileSimilarityScore(pastLoProfile,loProfile,options.merge({:filtering_los => false}))
      end
      losS = losS/userProfile[:los].length
    end

    return -1 if (!filters.blank? and (languageS < filters[:language] || losS < filters[:los]))

    return weights[:language] * languageS + weights[:los] * losS
  end

  #Quality Score, [0,1] scale
  #For Europeana Items, quality is the metadata quality obtained from the europeanaCompleteness field, which is a number in a 1-10 scale.
  def self.qualityScore(loProfile)
    return [[(loProfile[:quality]-1)/9.to_f,0].max,1].min
  end

  #Popularity Score, [0,1] scale
  #Popularity is calcuated in the 'context:updatePopularityMetrics' task. The popularity field is an integer in a 1-10 scale.
  def self.popularityScore(loProfile)
    return [[loProfile[:popularity]/100.to_f,0].max,1].min
  end


  private

  #######################
  ## Utils (private methods)
  #######################

  #Semantic distance in a [0,1] scale. 
  #It calculates the semantic distance using the Cosine similarity measure, and the TF-IDF function to calculate the vectors.
  def self.getSemanticDistance(textA,textB)
    return 0 unless (textA.is_a? String or textB.is_a? String)
    return 0 if (textA.blank? or textB.blank?)

    #We need to limit the length of the text due to performance issues
    textA = textA.first(EuropeanaRS::Application::config.max_text_length)
    textB = textB.first(EuropeanaRS::Application::config.max_text_length)

    numerator = 0
    denominator = 0
    denominatorA = 0
    denominatorB = 0

    wordsTextA = RecommenderSystem.processFreeText(textA)
    wordsTextB = RecommenderSystem.processFreeText(textB)

    # Get the text with more/less words.
    # words = [wordsTextA.keys, wordsTextB.keys].sort_by{|words| -words.length}.first

    #All words
    words = (wordsTextA.keys + wordsTextB.keys).uniq

    words.each do |word|
      #We could use here TFIDF as well. But we are going to use just the number of occurrences.
      occurrencesTextA = wordsTextA[word] || 0
      occurrencesTextB = wordsTextB[word] || 0
      wordIDF = RecommenderSystem.IDF(word)
      tfidf1 = RecommenderSystem.TFIDF(word,textA,{:occurrences => occurrencesTextA, :idf => wordIDF})
      tfidf2 = RecommenderSystem.TFIDF(word,textB,{:occurrences => occurrencesTextB, :idf => wordIDF})
      numerator += (tfidf1 * tfidf2)
      denominatorA += tfidf1**2
      denominatorB += tfidf2**2
    end

    denominator = Math.sqrt(denominatorA) * Math.sqrt(denominatorB)
    return 0 if denominator==0

    numerator/denominator
  end

  def self.processFreeText(text)
    return {} unless text.is_a? String
    text = text.gsub(/([\n])/," ")
    text =  I18n.transliterate(text.downcase.strip)
    words = Hash.new
    text.split(" ").each do |word|
      words[word] = 0 if words[word].nil?
      words[word] += 1
    end
    words
  end

  # Term Frequency (TF)
  def self.TF(word,text,options={})
    return options[:occurrences] if options[:occurrences].is_a? Numeric
    RecommenderSystem.processFreeText(text)[word] || 0
  end

  # Inverse Document Frequency (IDF)
  def self.IDF(word,options={})
    return options[:idf] if options[:idf].is_a? Numeric

    allResourcesInRepository = EuropeanaRS::Application::config.repository_total_entries
    # occurrencesOfWordInRepository = (Word.find_by_value(word).occurrences rescue 1) #Too slow for real time recommendations
    occurrencesOfWordInRepository = EuropeanaRS::Application::config.words[word] || 1

    allResourcesInRepository = [allResourcesInRepository,1].max
    occurrencesOfWordInRepository = [[occurrencesOfWordInRepository,1].max,allResourcesInRepository].min

    # Math::log10 for use base 10
    Math.log(allResourcesInRepository/occurrencesOfWordInRepository.to_f) rescue 1
  end

  # TF-IDF
  def self.TFIDF(word,text,options={})
    tf = RecommenderSystem.TF(word,text,options)
    return 0 if tf==0

    idf = RecommenderSystem.IDF(word,options)
    return 0 if idf==0

    return (tf * idf)
  end

  #Semantic distance between keyword arrays (in a 0-1 scale)
  def self.getTextArraySemanticDistance(textArrayA,textArrayB)
    return 0 if textArrayA.blank? or textArrayB.blank?
    return 0 unless textArrayA.is_a? Array and textArrayB.is_a? Array

    return getSemanticDistance(textArrayA.join(" "),textArrayB.join(" "))
  end

  #Semantic distance in a [0,1] scale.
  #It calculates the semantic distance for categorical fields.
  #Return 1 if both fields are equal, 0 if not.
  def self.getSemanticDistanceForCategoricalFields(stringA,stringB)
    stringA = RecommenderSystem.processFreeText(stringA).first[0] rescue nil
    stringB = RecommenderSystem.processFreeText(stringB).first[0] rescue nil
    return 0 if stringA.blank? or stringB.blank?
    return 1 if stringA === stringB
    return 0
  end

  #Semantic distance in a [0,1] scale.
  #It calculates the semantic distance for numeric values.
  def self.getSemanticDistanceForNumericFields(numberA,numberB,scale=[0,100])
    return 0 unless numberA.is_a? Numeric and numberB.is_a? Numeric
    numberA = [[numberA,scale[0]].max,scale[1]].min
    numberB = [[numberB,scale[0]].max,scale[1]].min
    (1-((numberA-numberB).abs)/(scale[1]-scale[0]).to_f) ** 2
  end

  #Year distance in a [0,1] scale.
  def self.getSemanticDistanceForYears(yearA,yearB)
    yearA = yearA.to_i if yearA.is_a? String
    yearB = yearB.to_i if yearB.is_a? String
    return 0 if yearA===0 or yearB===0
    RecommenderSystem.getSemanticDistanceForNumericFields(yearA,yearB,[1600,2015])
  end

  ############
  # Get user (or session) settings
  ############

  def self.getRSWeights(options={})
    getRSUserSetting("rs","weights",options)
  end

  def self.getLoSWeights(options={})
    getRSUserSetting("los","weights",options)
  end

  def self.getUSWeights(options={})
    getRSUserSetting("us","weights",options)
  end

  def self.getRSFilters(options={})
    getRSUserSetting("rs","filters",options)
  end

  def self.getLoSFilters(options={})
    getRSUserSetting("los","filters",options)
  end

  def self.getUSFilters(options={})
    getRSUserSetting("us","filters",options)
  end

  def self.getRSUserSetting(settingName,settingFamily,options={})
    settingKey = (settingName + "_" + settingFamily).to_sym #e.g. :rs_weights

    explicitSettings = {}
    explicitSettings = options[:settings][settingKey] || {} if options[:settings]

    userSettings = options[:user_settings][settingKey] if options[:user_settings]
    if userSettings.blank?
      defaultKey = ("default_" + settingName).to_sym #e.g. :default_rs
      case settingFamily
      when "weights"
        europeanaRSConfig = EuropeanaRS::Application::config.weights
      when "filters"
        europeanaRSConfig = EuropeanaRS::Application::config.filters
      end
      userSettings = europeanaRSConfig[defaultKey] unless europeanaRSConfig.nil?
    end

    userSettings.merge(explicitSettings)
  end

  # Default weights for the Recommender System provided by EuropeanaRS
  # These weights can be overriden in the application_config.yml file.
  # The current default weights can be accesed in the EuropeanaRS::Application::config.weights variable.
  def self.defaultRSWeights
    {
      :los_score => 0.4,
      :us_score => 0.4,
      :quality_score => 0.10,
      :popularity_score => 0.10
    }
  end

  def self.defaultLoSWeights
    {
      :title => 0.2,
      :description => 0.15,
      :language => 0.5,
      :year => 0.15
    }
  end

  def self.defaultUSWeights
    {
      :language => 0.5,
      :los => 0.5
    }
  end

  def self.defaultPopularityWeights
    {
      :visit_count => 0.5,
      :like_count => 0.5
    }
  end

  # Default filters for the Recommender System provided by EuropeanaRS
  # These filters can be overriden in the application_config.yml file.
  # The current default filters can be accesed in the EuropeanaRS::Application::config.filters variable.
  def self.defaultRSFilters
    {
      :los_score => 0,
      :us_score => 0,
      :quality_score => 0,
      :popularity_score => 0
    }
  end

  def self.defaultLoSFilters
    {
      :title => 0,
      :description => 0,
      :language => 0,
      :year => 0
    }
  end

  def self.defaultUSFilters
    {
      :language => 0,
      :los => 0
    }
  end

end