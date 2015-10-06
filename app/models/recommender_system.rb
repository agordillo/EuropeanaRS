# encoding: utf-8

###############
# EuropeanaRS Recommender System
###############

class RecommenderSystem

  def self.resource_suggestions(options={})

    # Step 0: Initialize all variables
    options = prepareOptions(options)

    #Step 1: Preselection
    preSelectionLOs = getPreselection(options)

    #Step 2: Scoring
    rankedLOs = orderByScore(preSelectionLOs,options)

    #Step 3
    return rankedLOs.first(options[:n])
  end

  # Step 0: Initialize all variables
  def self.prepareOptions(options={})
    options
  end

  #Step 1: Preselection
  def self.getPreselection(options={})
    preSelection = []

    # Search resources using the search engine
    # TODO.

    return preSelection
  end

  #Step 2: Scoring
  def self.orderByScore(preSelectionLOs,options)

    if preSelectionLOs.blank?
      return preSelectionLOs
    end

    preSelectionLOs.map{ |lo|
      # TODO: Calculate score
      lo.score = 1
    }

    preSelectionLOs.sort! { |a,b|  b.score <=> a.score }
  end

  #Content Similarity Score (between 0 and 1)
  def self.contentSimilarityScore(loA,loB)
    weights = {}
    weights[:title] = 0.2
    weights[:description] = 0.15
    weights[:language] = 0.5
    weights[:years] = 0.15
    
    titleS = 0
    descriptionS = 0
    languageS = 0
    years = 0

    return weights[:title] * titleS + weights[:description] * descriptionS + weights[:language] * languageD + weights[:years] * yearsD
  end

  #User profile Similarity Score (between 0 and 1)
  def self.userProfileSimilarityScore(user,lo)
    weights = {}
    weights[:language] = 1

    languageD = 0

    return weights[:language] * languageD
  end

  #Popularity Score (between 0 and 1)
  def self.popularityScore(lo,maxPopularity)
    return 0
  end

  #Quality Score (between 0 and 1)
  # Metadata quality is the europeanaCompleteness field, which is a  number in a 1-10 scale.
  def self.qualityScore(lo,maxQualityScore)
    return [[(lo.metadata_quality-1)/9.to_f,0].max,1].min rescue 0
  end


  private

  #######################
  ## Utils (private methods)
  #######################

  #Semantic distance in a [0,1] scale.
  #It calculates the semantic distance using the Cosine similarity measure, and the TF-IDF function to calculate the vectors.
  def self.getSemanticDistance(textA,textB)
    return 0 if (textA.blank? or textB.blank?)

    numerator = 0
    denominator = 0
    denominatorA = 0
    denominatorB = 0

    wordsTextA =  RecommenderSystem.processFreeText(textA)
    wordsTextB =  RecommenderSystem.processFreeText(textB)

    # Get the text with more/less words.
    # words = [wordsTextA.keys, wordsTextB.keys].sort_by{|words| -words.length}.first

    #All words
    words = (wordsTextA.keys + wordsTextB.keys).uniq

    words.each do |word|
      #We could use here TFIDF as well. But we are going to use just the number of occurrences.
      occurrencesTextA = wordsTextA[word] || 0
      occurrencesTextB = wordsTextB[word] || 0
      tfidf1 = RecommenderSystem.TFIDF(word,textA,{:occurrences => occurrencesTextA})
      tfidf2 = RecommenderSystem.TFIDF(word,textB,{:occurrences => occurrencesTextB})
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
  def self.TF(word,text,options)
    return options[:occurrences] if options[:occurrences].is_a? Numeric
    RecommenderSystem.processFreeText(text)[word] || 0
  end

  # Inverse Document Frequency (IDF)
  # Not implemented yet
  def self.IDF(word,text,options)
    allResourcesInRepository = EuropeanaRS::Application::config.repository_total_entries
    occurrencesOfWordInRepository = 1 # TODO

    allResourcesInRepository = [allResourcesInRepository,1].max
    occurrencesOfWordInRepository = [occurrencesOfWordInRepository,1].max

    # Math::log10 for use base 10
    Math.log(allResourcesInRepository/occurrencesOfWordInRepository.to_f) rescue 1
  end

  # TF-IDF
  def self.TFIDF(word,text,options)
    tf = RecommenderSystem.TF(word,text,options)
    return 0 if tf==0

    idf = RecommenderSystem.IDF(word,text,options)
    return 0 if idf==0

    return (tf * idf)
  end

  #Semantic distance between keyword arrays (in a 0-1 scale)
  def self.getTextArraySemanticDistance(textArrayA,textArrayB)
    return 0 if textArrayA.blank? or textArrayB.blank?
    return 0 unless textArrayA.is_a? Array and textArrayB.is_a? Array

    return getSemanticDistance(textArrayA.join(" "),textArrayB.join(" "))
  end

end