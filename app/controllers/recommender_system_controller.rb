##################
# Recommender System API
# Documentation at https://github.com/agordillo/EuropeanaRS/wiki
##################

class RecommenderSystemController < ApplicationController

  # Enable CORS
  before_filter :cors_preflight_check, :only => [:api_resource_suggestions]
  after_filter :cors_set_access_control_headers, :only => [:api_resource_suggestions]


  def api
    options = {}
    suggestions = RecommenderSystem.suggestions(options)

    respond_to do |format|
      format.any {
        render :json => suggestions, :content_type => "application/json"
      }
    end
  end

end