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

  #Semantic distance (between 0 and 1)
  def self.getSemanticDistance(stringA,stringB)
    if stringA.blank? or stringB.blank?
      return 0
    end

    stringA =  I18n.transliterate(stringA.downcase.strip)
    stringB =  I18n.transliterate(stringB.downcase.strip)

    if stringA == stringB
      return 1
    else
      return 0
    end
  end

  #Semantic distance between keyword arrays (in a 0-1 scale)
  def self.getKeywordsDistance(keywordsA,keywordsB)
    if keywordsA.blank? or keywordsB.blank?
      return 0
    end 

    similarKeywords = 0
    kParam = [keywordsA.length,keywordsB.length].min

    keywordsA.each do |kA|
      keywordsB.each do |kB|
        if getSemanticDistance(kA,kB) == 1
          similarKeywords += 1
          break
        end
      end
    end

    return similarKeywords/kParam.to_f
  end

end