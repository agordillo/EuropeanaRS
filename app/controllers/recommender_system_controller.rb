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
  before_filter :authenticate_app_with_private_key, :only => [:create_app_user, :update_app_user, :destroy_app_user]
  before_filter :parse_json_fields, :only => [:api, :create_app_user, :update_app_user]


  def api
    #1. Sanitize params and parsing
    queryOptions = params.permit(EuropeanaRS::Application::config.api[:permitedParams]) rescue {}
    options = {:external => true}.merge(queryOptions.to_hash.recursive_symbolize_keys.parse_for_rs)

    #If user_id is provided for this app, retrieve user profile from database.
    if params["user_id"] and current_app
      userProfile = UserProfile.fromApp(current_app,params["user_id"],options[:user_profile])
      if userProfile.persisted?
        options[:user_profile] = userProfile.profile if options[:user_profile].blank?
      end
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


  ##################
  # App users REST API
  ##################

  def create_app_user
    #Sanitize params and parsing
    options = params.permit(EuropeanaRS::Application::config.api[:permitedParamsUsers]).to_hash.recursive_symbolize_keys rescue {}

    response = {}
    userProfile = nil

    if options[:user_id] and options[:user_profile] and current_app
      userProfile = UserProfile.where(app_id: current_app.id, id_app: options[:user_id]).first
      unless userProfile.nil?
        response["errors"] = "User profile already exists"
      else
        userProfile = UserProfile.fromApp(current_app,options[:user_id],options[:user_profile])
      end
    end

    if !userProfile.nil? and userProfile.persisted? and response["errors"].blank?
      response["user_profile"] = userProfile.profile
    elsif response["errors"].blank?
      response["errors"] = "User couldn't be created"
    end

    render :json => response, :content_type => "application/json"
  end

  def update_app_user
    #Sanitize params and parsing
    params["feedback"] = JSON.parse(params["feedback"]) rescue [] unless params["feedback"].blank?
    options = params.permit(EuropeanaRS::Application::config.api[:permitedParamsUsers]).to_hash.recursive_symbolize_keys rescue {}

    response = {}
    userProfile = nil

    if params[:id] and (options[:feedback] or options[:user_profile]) and current_app
      userProfile = UserProfile.where(app_id: current_app.id, id_app: params[:id]).first
      if userProfile.nil?
        response["errors"] = "User profile not exists"
      else
        if options[:user_profile]
          response["errors"] = "User couldn't be updated" unless userProfile.updateFromUserProfile(options[:user_profile])
        end
        if options[:feedback] and response["errors"].blank?
          response["errors"] = "User couldn't be updated with feedback" unless userProfile.updateFromFeedback(options[:feedback])
        end
      end
    end

    if !userProfile.nil? and userProfile.persisted? and response["errors"].blank?
      response["user_profile"] = userProfile.profile
    elsif response["errors"].blank?
      response["errors"] = "User couldn't be updated"
    end

    render :json => response, :content_type => "application/json"
  end

  def destroy_app_user
    response = {}
    userProfile = nil
    
    userProfile = UserProfile.where(app_id: current_app.id, id_app: params[:id]).first if params[:id] and current_app

    if userProfile.nil?
      response["errors"] = "User profile not exists"
    else
      userProfile.destroy
    end

    response["status"] = "Done" if response["errors"].blank?

    render :json => response, :content_type => "application/json"
  end


  private

  def authenticate_app
    begin
      @current_app = App.find_by_app_key(params.require(:api_key))
      raise Error.new('Invalid API key') unless current_app.is_a? App
    rescue
      return unless EuropeanaRS::Application::config.api[:require_key]
      return render :json => ["Unauthorized"], :status => :unauthorized
    end
  end

  def authenticate_app_with_private_key
    return unless EuropeanaRS::Application::config.api[:require_key]
    begin
      raise Error.new('Invalid API key') if params.require(:private_key) != current_app.app_secret
    rescue
      return render :json => ["Unauthorized"], :status => :unauthorized
    end
  end

  def parse_json_fields
    unless params.blank? 
      unless params["user_profile"].blank? or params["user_profile"]["los"].blank?
        params["user_profile"]["los"] = JSON.parse(params["user_profile"]["los"]).first(EuropeanaRS::Application::config.max_user_los) rescue []
      end
    end
  end

end