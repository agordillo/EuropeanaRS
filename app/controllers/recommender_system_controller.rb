##################
# Recommender System API
# Documentation at https://github.com/agordillo/EuropeanaRS/wiki
##################

class RecommenderSystemController < ApplicationController

  # Disable default protect_from_forgery policy
  protect_from_forgery with: :exception, :except => [:api]
  protect_from_forgery with: :null_session

  # Enable CORS
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  # Authenticate applications
  before_filter :authenticate_app


  def api
    #1. Sanitize params and parsing
    unless params["user_profile"].blank?
      params["user_profile"]["los"] = JSON.parse(params["user_profile"]["los"]).first(EuropeanaRS::Application::config.max_user_los) rescue [] unless params["user_profile"]["los"].blank?
    end

    permitedParamsLo = [:title, :description, :language, :year, :repository, :id_repository]
    permitedParamsUser = [:language, los: permitedParamsLo]
    permitedParamsUserFields = permitedParamsUser.map{|k| k.is_a?(Hash) ? k.keys.first : k}
    permitedParamsGeneralWeights = [:los_score, :us_score, :quality_score, :popularity_score]
    permitedParamsSettings = [:preselection_size, :preselection_filter_languages, rs_weights: permitedParamsGeneralWeights , los_weights: permitedParamsLo, us_weights: permitedParamsUserFields, rs_filters: permitedParamsGeneralWeights, los_filters: permitedParamsLo, us_filters: permitedParamsUserFields]
    queryOptions = params.permit(:n, :query, lo_profile: permitedParamsLo, user_profile: permitedParamsUser, settings: permitedParamsSettings)
    options = {:external => true}.merge(queryOptions.to_hash.recursive_symbolize_keys)

    unless options[:settings].blank?
      options[:settings].each{ |k1,v1|
        v1.each{ |k2,v2| options[:settings][k1][k2] = v2.to_f } if v1.is_a? Hash
      }
      options[:settings][:preselection_size] = options[:settings][:preselection_size].to_i if options[:settings][:preselection_size].present?
      options[:settings][:preselection_filter_languages] = (options[:settings][:preselection_filter_languages]=="true") if options[:settings][:preselection_filter_languages].present?
    end

    #2. Call EuropeanaRS Recommender System
    suggestions = RecommenderSystem.suggestions(options)

    #3. Send response
    response = {}
    response["app_key"] = current_app.app_key if current_app
    response["params"] = queryOptions
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


  private

  def authenticate_app
    if EuropeanaRS::Application::config.api[:require_key]
      begin
       @current_app = App.find_by_app_key(params.require(:api_key))
       raise Error.new('invalid api key') unless current_app.is_a? App
      rescue
        return render :json => ["Unauthorized"], :status => :unauthorized
      end
    end
  end

end