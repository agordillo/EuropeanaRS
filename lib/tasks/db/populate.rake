namespace :db do

  namespace :populate do
    
    # How to use:
    # bundle exec rake db:populate:start["SEARCH",1,"newspapers","en"]
    task :start, [:mode, :start, :collection, :language, :type] => :environment do |t, args|
      puts "Populating database"
      t1 = Time.now

      args.with_defaults(:mode => "SEARCH", :start => 1, :collection => nil, :language => nil, :type => nil)
      start = [1,args[:start].to_i].max

      if args[:API] === "OAI-PMH"
        Rake::Task["db:populate:OAI_PMH"].invoke(start,args[:collection],args[:language],args[:type])
      else
        Rake::Task["db:populate:SEARCH_API"].invoke(start,args[:collection],args[:language],args[:type])
      end

      puts "Task finished"
      t2 = Time.now - t1
      puts "Elapsed time:" + t2.to_s
    end

    task :SEARCH_API, [:start, :collection, :language, :type] => :environment do |t, args|
      puts "Populating database using the Europeana Search API"

      args.with_defaults(:start => 1, :collection => nil, :language => nil, :type => nil)

      queryParams = {}

      queryParams[:start] = args[:start].to_i
      queryParams[:rows] = 100
      queryParams[:profile] = "rich"

      unless args[:collection].blank?
        case args[:collection]
          when "newspapers"
            queryParams[:skos_concept] = "http://vocab.getty.edu/aat/300026656"
            queryParams[:type] = "TEXT"
          # when "new_collection"
          #   queryParams[:skos_concept] = ""
          #   ...
          else
            if !args[:collection].match(/^http:\/\/vocab.getty.edu\/aat\/[0-9]+/).nil?
              queryParams[:skos_concept] = args[:collection]
            else
              queryParams[:europeana_collectionName] = args[:collection]
            end
          end
      end

      unless args[:language].blank?
        queryParams[:dclanguage] = args[:language]
        unless !queryParams[:europeana_collectionName].nil?
          #If a collection is specified, do not filter by provider language
          queryParams[:language] = args[:language]
        end
      end

      unless args[:type].blank?
        if queryParams[:type].blank?
          queryParams[:type] = args[:type]
        end
      end

      query = Europeana::Search.buildQuery(queryParams)

      require 'rest-client'
      response = (RestClient.get query) rescue nil
      parsed_response = JSON.parse(response) rescue nil

      if parsed_response.nil?
        puts "Error connecting to Europeana. Database population canceled."
        exit 1
      end

      totalResults = parsed_response["totalResults"]
      iterations = ((totalResults-queryParams[:start]+1)/queryParams[:rows].to_f).ceil

      puts "Query for population is: " + query

      for i in 1..iterations
        # puts "Value of nInteration is #{i}"
        query = Europeana::Search.buildQuery(queryParams)
        querySuccess = perform_search_query(query)
        unless querySuccess
          puts "Error connecting to Europeana. Database population canceled. Query: " + query
          exit 1
        else
          puts "Succesfully populated from " + queryParams[:start].to_s + " to " + (queryParams[:start] + queryParams[:rows] - 1).to_s
        end
        queryParams[:start] += queryParams[:rows]
        sleep 2
      end
    end

    def perform_search_query(query,nAttempt=0)
      begin
        response = (JSON.parse(RestClient.get query))
      rescue => e
        if nAttempt < 3
          sleep 5
          puts "Error on response. Retrying query..."
          return perform_search_query(query,nAttempt+1) 
        else
          response = nil
        end
      end

      return false if response.nil?

      response["items"].each do |europeanaItem|
        Europeana.createLoFromItem(europeanaItem)
      end

      true
    end

    task :OAI_PMH => :environment do
      puts "Populating database using the Europeana OAI-PMH service"
      #Currently, the Europeana OAI-PMH Service is in beta (http://labs.europeana.eu/api/oai-pmh-introduction).
      #Future work feature.
      puts "Not implemented yet"
    end

    # How to use:
    # bundle exec rake db:populate:parseMetadata
    task :parseMetadata, [:start] => :environment do |t, args|
      args.with_defaults(:start => 0)

      puts "Parsing Learning Object metadata from item " + args[:start].to_s

      ActiveRecord::Base.uncached do
        Lo.find_each(start: args[:start].to_i, batch_size: 1000).with_index do |lo, index|
          lo.save
          puts ("Index:" + index.to_s + " and LO:" + lo.id.to_s) if (index%5000===0)
        end
      end

      puts "Task finished"
    end

    # How to use:
    # bundle exec rake db:populate:popularityFields
    task :popularityFields => :environment do |t, args|
      puts "Populating popularity fields with random values"

      ActiveRecord::Base.uncached do
        Lo.find_each do |lo|
          lo.update_column :visit_count, (100 + rand(900))
          lo.update_column :like_count, (100 + rand(900))
        end
      end

      Rake::Task["context:updatePopularityMetrics"].invoke

      puts "Popularity fields population: Task finished"
    end

    # How to use:
    # bundle exec rake db:populate:install
    task :install => :environment do |t, args|
      puts "Populating database with initial values"

      Rake::Task["db:populate:clean"].invoke

      #Populate Users
      user = User.new
      user.email = "demo@europeanars.com"
      user.password = "demonstration"
      user.name = "Demo"
      user.ui_language = I18n.default_locale
      user.save!
      puts "User '" + user.name + "' created with email '" + user.email + "' and password 'demonstration'"

      #LOs liked by demo
      Lo.limit(3).order("RANDOM()").map{ |lo|
        user.like(lo)
      }

      #Populate Apps
      app = App.new
      app.user_id = User.find_by_email("demo@europeanars.com").id
      app.name = "EuropeanaRS"
      app.app_key = "demonstration"
      app.app_secret = app.app_key
      app.save!
      puts "App '" + app.name + "' created with app_key '" + app.app_key + "' and private key '" + app.app_secret + "'"

      puts "Installation completed"
    end

    # How to use:
    # bundle exec rake db:populate:install_production RAILS_ENV=production
    task :install_production => :environment do |t, args|
      puts "Starting installation"
      Rake::Task["db:populate:clean"].invoke
      puts "Installation completed"
    end

    # How to use:
    # bundle exec rake db:populate:clean
    task :clean => :environment do |t, args|
      puts "Removing all records from database (except LOs)"
      #Remove all records
      #LOs and Words are kept.
      #They are intended to be loaded from a dump file or generated via other population tasks (see populate:start).
      User.destroy_all
      UserProfile.destroy_all
      Evaluation.destroy_all
      App.destroy_all
      LoProfile.destroy_all
      Session.destroy_all
      Europeana::UserAuth.destroy_all
    end

  end

end

