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
    options = {:n => 10, :user_profile => {}, :lo_profile => {}, :settings => EuropeanaRS::Application::config.default_settings.recursive_merge({})}.recursive_merge(options)
    options[:user_profile][:los] = options[:user_profile][:los].first(options[:max_user_pastlos] || EuropeanaRS::Application::config.max_user_pastlos).sample(options[:max_user_los] || EuropeanaRS::Application::config.max_user_los) unless options[:user_profile][:los].blank?
    options
  end

  #Step 1: Preselection
  def self.getPreselection(options={})
    preSelection = []

    # Define some filters for the preselection
    options[:preselection] = {}
    
    # A. Query.
    options[:preselection][:query] = options[:settings][:query] unless options[:settings][:query].blank?

    # B. Resource type.
    unless options[:settings][:preselection_filter_resource_type] == false
      if Utils.getResourceTypes.include?(options[:lo_profile][:resource_type])
        options[:preselection][:resource_types] = options[:lo_profile][:resource_type]
      end
    end

    # C. Language.
    unless options[:settings][:preselection_filter_languages] == false
      # C. Multilanguage approach.
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
      preselectionLanguages = preselectionLanguages & Utils.getAllLanguages

      options[:preselection][:languages] = preselectionLanguages unless preselectionLanguages.blank?

      # C. (Alternative). Single language approach.
      # preselectionLanguage = nil
      # if options[:lo_profile][:language]
      #   preselectionLanguage = options[:lo_profile][:language]
      # elsif options[:user_profile][:language]
      #   preselectionLanguage = options[:user_profile][:language]
      # end
      # preselectionLanguage = nil unless Utils.getAllLanguages.include? preselectionLanguage 
      # options[:preselection][:languages] = [preselectionLanguage] unless preselectionLanguage.nil?
    end

    # D. Repeated resources.
    if options[:lo_profile][:id_repository]
      case options[:lo_profile][:repository]
      when "Europeana"
        options[:preselection][:europeana_id_to_avoid] = options[:lo_profile][:id_repository]
      end
    end

    preSelection += getPreselectionFromSearchEngine(options) unless options[:settings][:database] == "Europeana"
    preSelection += getPreselectionFromEuropeana(options) unless options[:settings][:database] == "EuropeanaRS"
    preSelection
  end

  def self.getPreselectionFromSearchEngine(options={})
    # Search resources using the search engine
    searchOptions = {}

    searchOptions[:n] = [options[:settings][:europeanars_database][:preselection_size],EuropeanaRS::Application::config.settings[:europeanars_database][:max_preselection_size]].min
    searchOptions[:models] = [Lo]
    searchOptions[:order] = "random"

    # Define preselection filters
    # A. Query
    searchOptions[:query] = options[:preselection][:query] unless options[:preselection][:query].blank?
    # B. Resource type
    searchOptions[:resource_types] = options[:preselection][:resource_types] unless options[:preselection][:resource_types].blank?
    # C. Language.
    searchOptions[:languages] = options[:preselection][:languages] unless options[:preselection][:languages].blank?
    # D. Repeated resources.
    searchOptions[:europeana_ids_to_avoid] = [options[:preselection][:europeana_id_to_avoid]] unless options[:preselection][:europeana_id_to_avoid].blank?

    # Get preselectin from Search Engine
    preSelection = Search.search(searchOptions)

    if preSelection.blank?
      #Try with other search options. Remove filters to try to get a non empty preselection.

      # Disable language filter
      if !searchOptions[:languages].blank?
        searchOptions.delete(:languages)
        preSelection = Search.search(searchOptions)
      end

      # Disable query filter
      if preSelection.blank? and !searchOptions[:query].blank?
        searchOptions.delete(:query)
        preSelection = Search.search(searchOptions)
      end
    end

    #Convert LOs to LO profiles
    return preSelection.map{|lo| lo.profile({:external => options[:external]})}
  end

  def self.getPreselectionFromEuropeana(options={})
    # Search resources in real time using the Europeana Search API
    options[:settings][:europeana_database][:query] = options[:settings][:europeana_database][:query].merge({:start => 1, :rows => 100, :profile => "rich"})

    # A. Query.
    options[:settings][:europeana_database][:query][:query] = options[:preselection][:query] unless options[:preselection][:query].blank?
    # B. Resource type.
    options[:settings][:europeana_database][:query][:type] = options[:preselection][:resource_types] unless options[:preselection][:resource_types].blank?
    # C. Language.
    options[:settings][:europeana_database][:query][:language] = options[:preselection][:languages] unless options[:preselection][:languages].blank?
    # D. Repeated resources.
    # Applied after retrieve results

    #Extra filters (Years, only if configured)
    if options[:settings][:europeana_database][:query][:year_range] and options[:lo_profile] and options[:lo_profile][:year]
      options[:settings][:europeana_database][:query][:year_min] = options[:lo_profile][:year]-options[:settings][:europeana_database][:query][:year_range]
      options[:settings][:europeana_database][:query][:year_max] = options[:lo_profile][:year]+options[:settings][:europeana_database][:query][:year_range]
    end

    n = [options[:settings][:europeana_database][:preselection_size],EuropeanaRS::Application::config.settings[:europeana_database][:max_preselection_size]].min

    require 'rest-client'
    nRequests = (n/100.to_f).ceil
    europeanaItems = []
    europeanaQueryIndexes = [1] #First request page 1
    currentQueryIndex = 0

    nRequests.times do |i|
      break if europeanaQueryIndexes[currentQueryIndex].nil?
      options[:settings][:europeana_database][:query][:start] = europeanaQueryIndexes[currentQueryIndex]
      query = Europeana::Search.buildQuery(options[:settings][:europeana_database][:query])
      response = (JSON.parse(RestClient::Request.execute(:method => :get, :url => query, :timeout => 5, :open_timeout => 5))) rescue nil #nil => error connecting to Europeana
      unless response.nil?
        europeanaItems += response["items"]
        if currentQueryIndex==0
          #Define random indexes for subsequent requests
          remainingRequests = nRequests-1
          break if (remainingRequests<1)
          remainingResults = response["totalResults"]-100
          break if (remainingResults<1)
          segmentSize = remainingResults/remainingRequests
          if segmentSize < 100
            remainingRequests = (remainingResults/100.to_f).ceil
            segmentSize = 100
          end
          remainingRequests.times do |i|
            europeanaQueryIndexes << (100 + i*segmentSize + rand(segmentSize-100)).floor
          end
        end
        currentQueryIndex += 1
      end
    end

    # Convert Europeana items to LO profiles
    loProfiles = europeanaItems.map{|item| Europeana.createVirtualLoProfileFromItem(item,{:external => options[:external]})}

    # D. Repeated resources.
    loProfiles = loProfiles.reject{|loProfile| loProfile[:id_repository] == options[:preselection][:europeana_id_to_avoid]} unless options[:preselection][:europeana_id_to_avoid].blank?

    return loProfiles
  end

  #Step 2: Scoring
  def self.calculateScore(preSelectionLOs,options)
    return preSelectionLOs if preSelectionLOs.blank?

    weights = getRSWeights(options)
    weights_sum = 1
    options[:weights_los] = getLoSWeights(options)
    options[:weights_us] = getUSWeights(options)

    filters = getRSFilters(options)

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
      options[:filters_los] = getLoSFilters(options)
      options[:filtering_los] = options[:filters_los].map {|k,v| v}.sum > 0
    end
    if options[:filtering_us].nil?
      options[:filters_us] = getUSFilters(options)
      options[:filtering_us] = options[:filters_us].map {|k,v| v}.sum > 0
    end

    calculateLoSimilarityScore = ((weights[:los_score]>0)||(filters[:los_score]>0)||options[:filtering_los])
    calculateUserSimilarityScore = ((weights[:us_score]>0)||(filters[:us_score]>0)||options[:filtering_us] )
    calculateQualityScore = ((weights[:quality_score]>0)||(filters[:quality_score]>0))
    calculatePopularityScore = ((weights[:popularity_score]>0)||(filters[:popularity_score]>0))

    preSelectionLOs.map{ |loProfile|
      los_score = calculateLoSimilarityScore ? loProfileSimilarityScore(options[:lo_profile],loProfile,options) : 0
      (loProfile[:filtered]=true and next) if (calculateLoSimilarityScore and los_score < filters[:los_score])
      
      us_score = calculateUserSimilarityScore ? userProfileSimilarityScore(options[:user_profile],loProfile,options) : 0
      (loProfile[:filtered]=true and next) if (calculateUserSimilarityScore and us_score < filters[:us_score])
      
      quality_score = calculateQualityScore ? qualityScore(loProfile) : 0
      (loProfile[:filtered]=true and next) if (calculateQualityScore and quality_score < filters[:quality_score])
      
      popularity_score = calculatePopularityScore ? popularityScore(loProfile) : 0
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
    weights = options[:weights_los] || getLoSWeights(options)
    filters = options[:filtering_los]!=false ? (options[:filters_los] || getLoSFilters(options)) : nil
    
    titleS = getSemanticDistance(loProfileA[:title],loProfileB[:title])
    descriptionS = getSemanticDistance(loProfileA[:description],loProfileB[:description])
    languageS = getSemanticDistanceForCategoricalFields(loProfileA[:language],loProfileB[:language])
    yearS = getSemanticDistanceForYears(loProfileA[:year],loProfileB[:year])

    return -1 if (!filters.blank? and (titleS < filters[:title] || descriptionS < filters[:description] || languageS < filters[:language] || yearS < filters[:year]))

    return weights[:title] * titleS + weights[:description] * descriptionS + weights[:language] * languageS + weights[:year] * yearS
  end

  #User profile Similarity Score, [0,1] scale
  def self.userProfileSimilarityScore(userProfile,loProfile,options={})
    weights = options[:weights_us] || getUSWeights(options)
    filters = options[:filtering_us]!=false ? (options[:filters_us] || getUSFilters(options)) : nil
    
    languageS = getSemanticDistanceForCategoricalFields(userProfile[:language],loProfile[:language])

    losS = 0
    unless userProfile[:los].blank?
      userProfile[:los].each do |pastLoProfile|
        losS += loProfileSimilarityScore(pastLoProfile,loProfile,options.merge({:filtering_los => false}))
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
    return 0 if (textA.blank? or textB.blank?)

    #We need to limit the length of the text due to performance issues
    textA = textA.first(EuropeanaRS::Application::config.max_text_length)
    textB = textB.first(EuropeanaRS::Application::config.max_text_length)

    numerator = 0
    denominator = 0
    denominatorA = 0
    denominatorB = 0

    wordsTextA = processFreeText(textA)
    wordsTextB = processFreeText(textB)

    #All words
    (wordsTextA.keys + wordsTextB.keys).uniq.each do |word|
      wordIDF = IDF(word)
      tfidf1 = (wordsTextA[word] || 0) * wordIDF
      tfidf2 = (wordsTextB[word] || 0) * wordIDF
      numerator += (tfidf1 * tfidf2)
      denominatorA += tfidf1**2
      denominatorB += tfidf2**2
    end

    denominator = Math.sqrt(denominatorA) * Math.sqrt(denominatorB)
    return 0 if denominator==0

    numerator/denominator
  end

  def self.processFreeText(text)
    return {} if text.blank?
    words = Hash.new
    normalizeText(text).split(" ").each do |word|
      words[word] = 0 if words[word].nil?
      words[word] += 1
    end
    words
  end

  def self.normalizeText(text)
    I18n.transliterate(text.gsub(/([\n])/," ").strip, :locale => "en").downcase
  end

  # Term Frequency (TF)
  def self.TF(word,text)
    processFreeText(text)[normalizeText(word)] || 0
  end

  # Inverse Document Frequency (IDF)
  def self.IDF(word)
    Math::log((2+EuropeanaRS::Application::config.repository_total_entries)/(1+(EuropeanaRS::Application::config.words[word] || 0)).to_f)
  end

  # TF-IDF
  def self.TFIDF(word,text)
    tf = TF(word,text)
    return 0 if tf==0
    return (tf * IDF(word))
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
    stringA = normalizeText(stringA) rescue nil
    stringB = normalizeText(stringB) rescue nil
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
    getSemanticDistanceForNumericFields(yearA,yearB,[1600,2015])
  end

  #Semantic distance in a [0,1] scale.
  #It calculates the semantic distance for languages.
  def self.getSemanticDistanceForLanguage(stringA,stringB)
    return 0 if ["independent","ot"].include? stringA
    return getSemanticDistanceForCategoricalFields(stringA,stringB)
  end

  #Semantic distance in a [0,1] scale.
  #It calculates the semantic distance for keywords.
  def self.getSemanticDistanceForKeywords(keywordsA,keywordsB)
    return 0 if keywordsA.blank? or keywordsB.blank?
    keywordsA = keywordsA.map{|k| normalizeText(k)}.uniq
    keywordsB = keywordsB.map{|k| normalizeText(k)}.uniq
    return (2*(keywordsA & keywordsB).length)/(keywordsA.length+keywordsB.length).to_f
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

    userSettings.recursive_merge(explicitSettings)
  end

  # Default weights for the Recommender System provided by EuropeanaRS
  # These weights can be overriden in the application_config.yml file.
  # The current default weights can be accesed in the EuropeanaRS::Application::config.weights variable.
  def self.defaultRSWeights
    {
      :los_score => 0.5,
      :us_score => 0.5,
      :quality_score => 0.0,
      :popularity_score => 0.0
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