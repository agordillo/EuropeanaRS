EuropeanaRS::Application::config.repository_total_entries = Lo.count

#Keep words in the cache
words = {}
Word.where("occurrences > ?",1).first(5000000).each do |word|
    words[word.value] = word.occurrences
end
EuropeanaRS::Application::config.words = words