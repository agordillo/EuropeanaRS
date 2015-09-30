namespace :db do

  namespace :populate do
    
    # How to use:
    # bundle exec rake db:populate:start["SEARCH",1,"newspapers"]
    task :start, [:mode, :start, :collection, :language] => :environment do |t, args|
      puts "Populating database"
      t1 = Time.now

      args.with_defaults(:mode => "SEARCH", :start => 1, :collection => nil, :language => nil)
      start = [1,args[:start].to_i].max

      if args[:API] === "OAI-PMH"
        Rake::Task["db:populate:OAI_PMH"].invoke(start,args[:collection],args[:language])
      else
        Rake::Task["db:populate:SEARCH_API"].invoke(start,args[:collection],args[:language])
      end

      puts "Task finished"
      t2 = Time.now - t1
      puts "Elapsed time:" + t2.to_s
    end

    task :SEARCH_API, [:start, :collection, :language] => :environment do |t, args|
      puts "Populating database using the Europeana Search API"

      args.with_defaults(:start => 1, :collection => nil, :language => nil)

      queryParams = {}

      queryParams[:start] = args[:start].to_i
      queryParams[:rows] = 100
      queryParams[:profile] = "rich"

      unless args[:collection].nil?
        case args[:collection]
          when "newspapers"
            queryParams[:skos_concept] = "http://vocab.getty.edu/aat/300026656"
            queryParams[:type] = "TEXT"
          # when "new_collection"
          #   queryParams[:skos_concept] = ""
          #   ...
          else
            queryParams[:europeana_collectionName] = args[:collection]
          end
      end

      unless args[:language].nil?
        queryParams[:dclanguage] = args[:language]
        unless !queryParams[:europeana_collectionName].nil?
          #If a collection is specified, do not filter by provider language
          queryParams[:language] = args[:language]
        end
      end

      query = EuropeanaSearch.buildQuery(queryParams)

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
        query = EuropeanaSearch.buildQuery(queryParams)
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
        Europeana.saveRecord(europeanaItem)
      end

      true
    end

    task :OAI_PMH => :environment do
      puts "Populating database using the Europeana OAI-PMH service"
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
  end

end

