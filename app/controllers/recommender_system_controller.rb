##################
# Recommender System API
# Documentation at https://github.com/agordillo/EuropeanaRS/wiki
##################

class RecommenderSystemController < ApplicationController

  # Enable CORS
  protect_from_forgery with: :exception, :except => [:api]
  protect_from_forgery with: :null_session, :only => [:api]

  before_filter :cors_preflight_check, :only => [:api]
  after_filter :cors_set_access_control_headers, :only => [:api]


  def api
    #1. Sanitize params and parsing
    unless params["user_profile"].blank?
      params["user_profile"]["los"] = JSON.parse(params["user_profile"]["los"]).first(EuropeanaRS::Application::config.max_user_los) rescue [] unless params["user_profile"]["los"].blank?
    end

    permitedParamsLo = [:title, :description, :language, :year, :id_europeana]
    permitedParamsUser = [:language, los: permitedParamsLo]
    permitedParamsWeights = [default_rs: [:los_score, :us_score, :quality_score, :popularity_score] , default_los: permitedParamsLo, default_us: permitedParamsUser.map{|k| k.is_a?(Hash) ? k.keys.first : k}]
    permitedParamsFilters = permitedParamsWeights
    permitedParamsSettings = [rs_weights: permitedParamsWeights, rs_filters: permitedParamsFilters]
    options = params.permit(:n, :query, lo_profile: permitedParamsLo, user_profile: permitedParamsUser, user_settings: permitedParamsSettings)
    options = {:external => true}.merge(options.to_hash.recursive_symbolize_keys)

    #2. Call EuropeanaRS Recommender System
    suggestions = RecommenderSystem.suggestions(options)

    #3. Send response
    response = {}
    response["params"] = options
    response["total_results"] = suggestions.length
    response["results"] = suggestions

    # Filter attributes like score, if desired.
    # suggestions = suggestions.map{|loProfile| loProfile.except(:score)}

    respond_to do |format|
      format.any {
        render :json => response, :content_type => "application/json"
      }
    end
  end

end