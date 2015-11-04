class SearchController < ApplicationController

  def search
    #Remove empty params   
    params.delete_if { |k, v| v == "" }

    n = params[:n] || 24
    page =  params[:page] || 1
    
    case params[:sort_by]
    when "year_asc"
      order = 'year ASC'
    when "year_desc"
      order = 'year DESC'
    when 'quality'
      order = 'metadata_quality DESC'
    when 'random'
      order = 'random'
    else
      #order by relevance
      order = nil
    end

    unless params[:ids_to_avoid].nil?
      params[:ids_to_avoid] = params[:ids_to_avoid].split(",")
    end

    models = [Lo]

    @results = Search.search({:query => params[:query], :n => n, :page => page, :order => order, :models => models, :ids_to_avoid => params[:ids_to_avoid], :resource_types => params[:resource_types], :languages => params[:languages], :year_min => params[:yearMin], :year_max => params[:yearMax] })
  end
  
end

