# encoding: utf-8

###############
# EuropeanaRS Search Engine Module
###############

class Search

  # Usage example: Search.search({:query=>"Madrid", :n=>10})
  # Search.search({:query => params[:q], :n => n, :page => page, :order => order, :models => models, :ids_to_avoid => params[:ids_to_avoid], :languages => params[:languages], :yearMin => params[:yearMin], :yearMax => params[:yearMax] })
  def self.search(options={})

    #Specify searchTerms
    if (![String,Array].include? options[:query].class) or (options[:query].is_a? String and options[:query].strip=="")
      browse = true
      searchTerms = ""
    else
      browse = false
      searchTerms = (options[:query].is_a?(String) ? options[:query].split(" ") : options[:query])

      #Sanitize search terms
      searchTerms = searchTerms.map{|st| Riddle::Query.escape(st) }
      #Remove keywords with less than 3 characters
      searchTerms = searchTerms.reject{|s| s.length < 3}
      #Perform an OR search
      searchTerms = searchTerms.join("|")
    end

    #Specify search options
    opts = {}

    n = nil
    unless options[:n].blank?
      n = options[:n].to_i rescue nil
    end
    unless n.is_a? Integer
      if !options[:page].nil?
        n = 24   #default results when pagination is requested
      else
        n = 9999 #default (All results found)
      end
    end
    n = [1,n].max

    opts[:per_page] = n

    opts[:match_mode] = :extended
    opts[:rank_mode] = :wordcount
    opts[:field_weights] = {
       :title => 50,
       :description => 1
    }
    
    opts[:max_matches] = EuropeanaRS::Application::config.max_matches if n > EuropeanaRS::Application::config.max_matches

    unless options[:page].nil?
      opts[:page] = options[:page].to_i rescue 1
    end

    if options[:order].is_a? String
      opts[:order] = options[:order]
    end

    if options[:models].is_a? Array
      opts[:classes] = options[:models]
    else
      opts[:classes] = [Lo]
    end

    opts[:with] = {}
    opts[:with_all] = {}

    #Filter by resource type
    unless options[:resource_types].blank?
      if options[:resource_types].is_a? String
        options[:resource_types] = options[:resource_types].split(",")
      end
      if options[:resource_types].is_a? Array and !options[:resource_types].blank?
        opts[:with][:resource_type] = options[:resource_types].map{|type| type.to_s.to_crc32}
      end
    end

    #Filter by language
    unless options[:languages].blank?
      if options[:languages].is_a? String
        options[:languages] = options[:languages].split(",")
      end
      if options[:languages].is_a? Array and !options[:languages].blank?
        opts[:with][:language] = options[:languages].map{|language| language.to_s.to_crc32}
      end
    end

    #Filter by year range
    if options[:year_min] or options[:year_max]

      unless options[:year_min].blank?
        yearMin = options[:year_min].to_i rescue 0
      else
        yearMin = 0
      end

      unless options[:year_max].blank?
        yearMax = options[:year_max].to_i rescue 9999
      else
        yearMax = 9999
      end

      yearMax = [[9999,yearMax].min,0].max
      yearMin = [yearMax,[yearMin,0].max].min

      opts[:with][:year] = yearMin..yearMax
    end

    opts[:without] = {}

    if options[:ids_to_avoid].is_a? Array
      options[:ids_to_avoid].compact!
      opts[:without][:lo_id] = options[:ids_to_avoid] unless options[:ids_to_avoid].empty?
    end

    if options[:europeana_ids_to_avoid].is_a? Array
      options[:europeana_ids_to_avoid].compact!
      unless options[:europeana_ids_to_avoid].empty?
        options[:europeana_ids_to_avoid].map!{|europeana_id| europeana_id.to_s.to_crc32}
        opts[:without][:id_europeana] = options[:europeana_ids_to_avoid]
      end
    end

    if opts[:classes].blank?
      #opts[:classes] blank will search for all classes by default. Set id to -1 to return empty results.
      opts[:with][:lo_id] = -1
    end

    # (Try to) Avoid nil results (See http://pat.github.io/thinking-sphinx/searching.html#nils)
    opts[:retry_stale] = true
    
    # Results sorting
    if opts[:order].blank?
      if browse==true
        #Browse can't order by relevance. Order randomly by default.
        opts[:order] = "random"
      else
        opts[:order] = nil
      end
    end

    if opts[:order] == "random"
      opts[:order] = 'RAND()'
    end

    #Filtering results without an attribute when sorting by this attribute.
    if opts[:order].is_a? String
      if opts[:order].include? "language" and opts[:with][:language].nil?
        opts[:without][:language] = 0
      end
      if opts[:order].include? "year" and opts[:with][:year].nil?
        opts[:without][:year] = 0
      end
    end

    return ThinkingSphinx.search searchTerms, opts
  end

end