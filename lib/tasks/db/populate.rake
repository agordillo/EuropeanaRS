namespace :db do

  namespace :populate do
    
    # How to use: 
    # bundle exec rake db:populate:start["SEARCH"]
    task :start, [:API] => :environment do |t, args|
      puts "Populating database"
      t1 = Time.now
      if args[:API] === "SEARCH"
        Rake::Task["db:populate:SEARCH_API"].invoke
      else
        Rake::Task["db:populate:OAI_PMH"].invoke
      end
      puts "Task finished"
      t2 = Time.now - t1
      puts "Elapsed time:" + t2.to_s
    end

    task :SEARCH_API => :environment do
      puts "Populating database using the Europeana Search API"
      europeana_SEARCH_API_KEY = EuropeanaRS::Application::config.APP_CONFIG["europeana_SEARCH_API_key"]
      
    end

    task :OAI_PMH => :environment do
      puts "Populating database using the Europeana OAI-PMH service"
      puts "Not implemented yet"
    end
  end

end

