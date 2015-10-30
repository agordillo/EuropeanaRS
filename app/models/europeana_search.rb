# encoding: utf-8

###############
# Class for using the Europeana Search API
###############

class EuropeanaSearch

  def self.buildQuery(params={})
    #Query example using the Europeana Search API
    #http://www.europeana.eu/api/v2/search.json?wskey=XXXX&query=skos_concept:%22http://vocab.getty.edu/aat/300026656%22&qf=TYPE:TEXT&profile=standard&rows=100&qf=YEAR:[1824+TO+1827]&qf=LANGUAGE:fr&qf=COUNTRY:france
    query = "http://www.europeana.eu/api/v2/search.json?wskey="+EuropeanaRS::Application::config.europeana[:api_key]+"&query="
    
    params.delete_if{|k,v| v.blank?} #Delete empty params

    #Convert arrays with one element into strings (prevent errors on Europeana API)
    params.each{ |k,v|
      params[k] = v.first if v.is_a? Array and v.length===1
    }

    if params[:query].is_a? String
      query += params[:query]
    else
      if params[:skos_concept].is_a? String
        query += 'skos_concept:%22' + params[:skos_concept] + '%22'
      elsif params[:europeana_collectionName].is_a? String
        query += 'europeana_collectionName:' + params[:europeana_collectionName]
      else
        query += "*"
      end
    end

    rows = ((params[:rows].is_a? Integer) ? params[:rows] : 100)
    query += "&rows=" + [100,rows].min.to_s

    start = ((params[:start].is_a? Integer) ? params[:start] : 1)
    query += "&start=" + [1,start].max.to_s

    profile = ((params[:profile].is_a? String) ? params[:profile] : "standard")
    query += "&profile=" + profile

    #Facets
    if params[:type].is_a? String and Utils.getResourceTypes.include?(params[:type])
      query += "&qf=TYPE:" + params[:type]
    elsif params[:type].is_a? Array
      params[:type] = (params[:type] & Utils.getResourceTypes)
      if params[:type].length > 1
        query += "&qf=TYPE:(" + params[:type].join("+OR+") + ")"
      elsif params[:type].length == 1
        query += "&qf=TYPE:" + params[:type].first
      end
    end

    if params[:year].is_a? Integer
      query += "&qf=YEAR:" + params[:year].to_s
    elsif params[:year_min].is_a? Integer and params[:year_max].is_a? Integer
      query += "&qf=YEAR:%5B" + params[:year_min].to_s + "+TO+" + params[:year_max].to_s + "%5D"
    end

    if params[:language].is_a? String
      query += "&qf=LANGUAGE:" + params[:language]
    elsif params[:language].is_a? Array
      query += "&qf=LANGUAGE:(" + params[:language].join("+OR+") + ")"
    end

    if params[:dclanguage].is_a? String
      query += "&qf=proxy_dc_language:" + params[:dclanguage]
    elsif params[:dclanguage].is_a? Array
      query += "&qf=proxy_dc_language:(" + params[:dclanguage].join("+OR+") + ")"
    end
    
    if params[:country].is_a? String
      query += "&qf=COUNTRY:" + params[:country]
    end

    query
  end

end