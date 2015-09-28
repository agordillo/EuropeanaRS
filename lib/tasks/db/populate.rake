namespace :db do

  namespace :populate do
    
    # How to use:
    # bundle exec rake db:populate:start["SEARCH",1,"newspapers"]
    task :start, [:mode, :start, :collection] => :environment do |t, args|
      puts "Populating database"
      t1 = Time.now

      args.with_defaults(:mode => "SEARCH", :start => 1, :collection => nil)
      start = [1,args[:start].to_i].max

      if args[:API] === "OAI-PMH"
        Rake::Task["db:populate:OAI_PMH"].invoke(start,args[:collection])
      else
        Rake::Task["db:populate:SEARCH_API"].invoke(start,args[:collection])
      end

      puts "Task finished"
      t2 = Time.now - t1
      puts "Elapsed time:" + t2.to_s
    end

    task :SEARCH_API, [:start, :collection] => :environment do |t, args|
      puts "Populating database using the Europeana Search API"

      args.with_defaults(:start => 1, :collection => nil)

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
          else
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
    task :parseMetadata => :environment do
      puts "Parsing Learning Object metadata"
      Lo.all.each do |lo|
        lo.save
      end
      puts "Task finished"
    end
  end

end

