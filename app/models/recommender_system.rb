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
    sortedLOs = filteredLOs.sort! { |a,b|  b.score <=> a.score }

    #Step 5: Delivering
    return sortedLOs.first(options[:n])
  end

  # Step 0: Initialize all variables
  def self.prepareOptions(options={})
    options = {:n => 10, :user_profile => {}, :lo_profile => {}}.merge(options)
    options
  end

  #Step 1: Preselection
  def self.getPreselection(options={})
    preSelection = []

    # Search resources using the search engine
    searchOptions = {};

    searchOptions[:n] = 100
    searchOptions[:models] = [Lo]

    # Define some filters for the preselection
    # A. Query
    searchOptions[:query] = options[:query] unless options[:query].blank?
    # B. Language
    preselectionLanguage = nil
    if options[:lo_profile][:language]
      preselectionLanguage = options[:lo_profile][:language]
    elsif options[:user_profile][:language]
      preselectionLanguage = options[:user_profile][:language]
    end
    searchOptions[:languages] = [preselectionLanguage] unless preselectionLanguage.nil?
    
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

    return preSelection
  end

  #Step 2: Scoring
  def self.calculateScore(preSelectionLOs,options)
    return preSelectionLOs if preSelectionLOs.blank?

    weights = RecommenderSystem.getRSWeights(options)

    weights_sum = 1
    if options[:lo_profile].blank?
      weights_sum = (weights_sum-weights[:los_score])
      weights[:los_score] = 0
    end
    if options[:user_profile].blank?
      weights_sum = (weights_sum-weights[:los_score])
      weights[:us_score] = 0
    end
    weights.each { |k, v| weights[k] = v/weights_sum.to_f } if weights_sum < 1

    calculateLoSimilarityScore = (weights[:los_score]>0)
    calculateUserSimilarityScore = (weights[:us_score]>0)
    calculateQualityScore = (weights[:quality_score]>0)
    calculatePopularityScore = (weights[:popularity_score]>0)

    preSelectionLOs.map{ |lo|
      loProfile = lo.profile

      los_score = calculateLoSimilarityScore ? RecommenderSystem.loProfileSimilarityScore(options[:lo_profile],loProfile) : 0
      us_score = calculateUserSimilarityScore ? RecommenderSystem.userProfileSimilarityScore(options[:user_profile],loProfile) : 0
      quality_score = calculateQualityScore ? RecommenderSystem.qualityScore(lo) : 0
      popularity_score = calculatePopularityScore ? RecommenderSystem.popularityScore(lo) : 0

      lo.score = weights[:los_score] * los_score + weights[:us_score] * us_score + weights[:quality_score] * quality_score + weights[:popularity_score] * popularity_score
    }

    preSelectionLOs
  end

  #Step 3: Filtering
  def self.filter(rankedLOs,options)
    filteredLOs = rankedLOs
    filteredLOs
  end


  #######################
  ## Utils for Scoring the Learning Objects
  #######################

  #Learning Object Similarity Score, [0,1] scale
  def self.loProfileSimilarityScore(loProfileA,loProfileB)
    weights = {}
    weights[:title] = 0.2
    weights[:description] = 0.15
    weights[:language] = 0.5
    weights[:years] = 0.15
    
    titleS = RecommenderSystem.getSemanticDistance(loProfileA[:title],loProfileB[:title])
    descriptionS = RecommenderSystem.getSemanticDistance(loProfileA[:description],loProfileB[:description])
    languageS = RecommenderSystem.getSemanticDistanceForCategoricalFields(loProfileA[:language],loProfileB[:language])
    yearsS = RecommenderSystem.getSemanticDistanceForYears(loProfileA[:year],loProfileB[:year])

    return weights[:title] * titleS + weights[:description] * descriptionS + weights[:language] * languageS + weights[:years] * yearsS
  end

  #User profile Similarity Score, [0,1] scale
  def self.userProfileSimilarityScore(userProfile,loProfile)
    weights = {}
    weights[:language] = 1

    languageD = 0

    return weights[:language] * languageD
  end

  #Quality Score, [0,1] scale
  #Metadata quality is the europeanaCompleteness field, which is a  number in a 1-10 scale.
  def self.qualityScore(lo)
    return [[(lo.metadata_quality-1)/9.to_f,0].max,1].min rescue 0
  end

  #Popularity Score, [0,1] scale
  def self.popularityScore(lo)
    #TODO
    return 0
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
    textA = textA.first(EuropeanaRS::Application::config.maxTextLength)
    textB = textB.first(EuropeanaRS::Application::config.maxTextLength)

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
    explicitRSWeights = options[:rs_weights] || {}
    userRSWeights = options[:user_settings][:rs_weights] if options[:user_settings]
    userRSWeights = RecommenderSystem.defaultRSWeights if userRSWeights.blank?
    userRSWeights.merge(explicitRSWeights)
  end

  def self.defaultRSWeights
    {
      :los_score => 0.4,
      :us_score => 0.4,
      :quality_score => 0.10,
      :popularity_score => 0.10
    }
  end

end