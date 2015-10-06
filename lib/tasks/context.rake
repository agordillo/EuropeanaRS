# encoding: utf-8

namespace :context do

  #How to use: bundle exec rake context:update
  task :update => :environment do |t, args|
    puts "Updating EuropeanaRS context"
    Rake::Task["context:updateWordsFrequency"].invoke
    puts "Task finished"
  end

  #How to use: bundle exec rake context:updateWordsFrequency
  task :updateWordsFrequency => :environment do |t, args|
    puts "Updating Words Frequency (for calculating TF-IDF)"

    #1. Remove previous metadata records
    Word.destroy_all

    #2. Retrieve words from LO metadata
    Lo.all.each do |lo|
      processText(lo.title)
      processText(lo.description)
    end

    #3. Add stopwords
    #   For stopwords, the occurences of the word record is set to the 'EuropeanaRS::Application::config.repository_total_entries' value.
    #   This way, the IDF for this word will be 0, and therefore the TF-IDF will be 0 too. This way, the word is ignored when calcuting the TF-IDF.
    EuropeanaRS::Application::config.stopwords.each do |stopword|
      wordRecord = Word.find_by_value(stopword)
      if wordRecord.nil?
        wordRecord = Word.new
        wordRecord.value = stopword
      end
      wordRecord.occurrences = EuropeanaRS::Application::config.repository_total_entries
      wordRecord.save!
    end
  end

  def processText(text)
    return if text.blank? or !text.is_a? String
    RecommenderSystem.processFreeText(text).each do |word,occurrences|
      wordRecord = Word.find_by_value(word)
      if wordRecord.nil?
        wordRecord = Word.new
        wordRecord.value = word
      end
      wordRecord.occurrences += occurrences
      wordRecord.save!
    end
  end

end

 