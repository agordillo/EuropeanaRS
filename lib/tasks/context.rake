# encoding: utf-8

namespace :context do

  #How to use: bundle exec rake context:update
  task :update => :environment do |t, args|
    puts "Updating EuropeanaRS context"
    Rake::Task["context:clearExpiredSessions"].invoke
    Rake::Task["context:updatePopularityMetrics"].invoke
    Rake::Task["context:updateWordsFrequency"].invoke
    puts "Task finished"
  end

  #How to use: bundle exec rake context:clearExpiredSessions
  task :clearExpiredSessions => :environment do
    sql = "DELETE FROM sessions WHERE updated_at < (CURRENT_TIMESTAMP - INTERVAL '1 seconds');" #PostgreSQL
    # sql = 'DELETE FROM sessions WHERE updated_at < DATE_SUB(NOW(), INTERVAL 1 DAY);' #MySQL
    ActiveRecord::Base.connection.execute(sql)
  end

  #Usage
  #Development:   bundle exec rake context:updatePopularityMetrics
  task :updatePopularityMetrics => :environment do
    puts "Updating popularity metrics"
    timeStart = Time.now
    
    popularityWeights = EuropeanaRS::Application::config.weights[:popularity]

    #Multiply each weight by 100, to store the popularity in a 0-100 scale.
    popularityWeights.each do |key,value|
      popularityWeights[key] *= 100
    end

    #Calculate maximumns
    maxVisitCount = [Lo.order('visit_count DESC').first.visit_count,1].max
    maxLikeCount = [Lo.order('like_count DESC').first.like_count,1].max

    #Calculate popularity for each Learning Object
    Lo.all.each do |lo|
      popularity = (lo.visit_count/maxVisitCount.to_f) * popularityWeights[:visit_count] + (lo.like_count/maxLikeCount.to_f) * popularityWeights[:like_count]
      popularity = [0,[popularity.round,100].min].max
      lo.update_column :popularity, popularity if popularity != lo.popularity
    end

    #Normalize popularity
    maxPopularity = [Lo.order('popularity DESC').first.popularity,1].max
    Lo.all.each do |lo|
      popularity = (lo.popularity/maxPopularity.to_f) * 100
      popularity = [0,[popularity.round,100].min].max
      lo.update_column :popularity, popularity if popularity != lo.popularity
    end

    timeFinish = Time.now
    puts "Updating popularity: Task finished"
    puts "Elapsed time: " + (timeFinish - timeStart).round(1).to_s + " (s)"
  end

  #How to use: bundle exec rake context:updateWordsFrequency
  task :updateWordsFrequency => :environment do |t, args|
    puts "Updating Words Frequency (for calculating TF-IDF)"

    #1. Remove previous metadata records
    Word.destroy_all

    #2. Retrieve words from LO metadata
    Lo.all.each do |lo|
      processResourceText((lo.title||"")+(lo.description||""))
    end

    #3. Add stopwords
    # For stopwords, the occurences of the word record is set to the 'EuropeanaRS::Application::config.repository_total_entries' value.
    # This way, the IDF for this word will be 0, and therefore the TF-IDF will be 0 too. This way, the word is ignored when calcuting the TF-IDF.
    # Stop words are readed from the file stopwords.yml
    stopwords = File.read("config/stopwords.yml").split(",").map{|s| s.gsub("\n","").gsub("\"","") } rescue []
    stopwords.each do |stopword|
      wordRecord = Word.find_by_value(stopword)
      if wordRecord.nil?
        wordRecord = Word.new
        wordRecord.value = stopword
      end
      wordRecord.occurrences = EuropeanaRS::Application::config.repository_total_entries
      wordRecord.save!
    end
    
    puts "Task finished"
  end

  def processResourceText(text)
    return if text.blank? or !text.is_a? String
    RecommenderSystem.processFreeText(text).each do |word,occurrences|
      wordRecord = Word.find_by_value(word)
      if wordRecord.nil?
        wordRecord = Word.new
        wordRecord.value = word
      end
      wordRecord.occurrences += 1
      wordRecord.save! rescue nil #This can be raised for too long words (e.g. long urls)
    end
  end

end

 