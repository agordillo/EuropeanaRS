# encoding: utf-8

###############
# EuropeanaRS Search Engine Module
###############

class Search

  # Usage example: Search.search({:query=>"Madrid", :n=>10})
  # Search.search({:query => params[:q], :n => n, :page => page, :order => order, :models => models, :ids_to_avoid => params[:ids_to_avoid], :language => params[:language], :yearMin => params[:yearMin], :yearMax => params[:yearMax] })
  def self.search(options={})

    #Specify searchTerms
    if (![String,Array].include? options[:query].class) or (options[:query].is_a? String and options[:query].strip=="")
      browse = true
      searchTerms = ""
    else
      browse = false
      if options[:query].is_a? String    
        searchTerms = options[:query].gsub(/[^0-9a-z&áéíóú]/i, ' ').split(" ")
      else
        searchTerms = options[:query].map{|s| s.gsub(/[^0-9a-z&áéíóú]/i, ' ')}
      end
      #Remove keywords with less than 3 characters
      searchTerms.reject!{|s| s.length < 3}
      searchTerms = searchTerms.join(" ")
    end

    #Specify search options
    opts = {}

    if options[:n].is_a? Integer
      n = options[:n]
    else
      if !options[:page].nil?
        n = 24   #default results when pagination is requested
      else
        n = 9999 #default (All results found)
      end
    end
    opts[:per_page] = n

    opts[:match_mode] = :extended
    opts[:rank_mode] = :wordcount
    opts[:field_weights] = {
       :title => 50,
       :description => 1
    }

    if n > 9999
      opts[:max_matches] = 9999
    end

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

    #Filter by language
    if options[:language]
      opts[:with][:language] = [options[:language].to_s.to_crc32]
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
      options[:ids_to_avoid] = options[:ids_to_avoid].compact
      unless options[:ids_to_avoid].empty?
        opts[:without][:lo_id] = options[:ids_to_avoid]
      end
    end

    if opts[:classes].blank?
      #opts[:classes] blank will search for all classes by default. Set id to -1 to return empty results.
      opts[:with][:lo_id] = -1
    end

    # (Try to) Avoid nil results (See http://pat.github.io/thinking-sphinx/searching.html#nils)
    opts[:retry_stale] = true
    
    if browse==true
      #Browse can't order by relevance. Order by year by default.
      opts[:order] = 'year ASC'
    end

    return ThinkingSphinx.search searchTerms, opts
  end

end