##################
# Recommender System API
# Documentation at https://github.com/agordillo/EuropeanaRS/wiki
##################

class LosApiController < ApplicationController

  # Disable default protect_from_forgery policy
  protect_from_forgery with: :exception, :except => [:api]
  
  #Disable 'X-Frame-Options' (Allow iframes)
  before_filter :allow_iframe_requests

  # Enable CORS
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  def api
    #1. Sanitize params and parsing
    options = params.permit(EuropeanaRS::Application::config.api[:permitedParamsLos])
    options = {:external => true}.merge(options.to_hash.parse_for_rs)

    if options[:id_europeana] and options[:lo_profile].blank?
      lo = Lo.find_by_id_europeana(options[:id_europeana])
      options[:lo_profile] = lo.profile unless lo.nil?
    end

    # This lines allows to keep the current profile in the session.
    # if options[:lo_profile].blank?
    #   if request.get?
    #     storedLoProfile = get_lo_profile_from_session
    #     options[:lo_profile] = storedLoProfile.parse_for_rs unless storedLoProfile.blank?
    #   end
    # else
    #   store_lo_profile_in_session(options[:lo_profile])
    # end

    #2. Call EuropeanaRS Recommender System
    @suggestions = RecommenderSystem.suggestions(options)
    @suggestions.each{|lo| lo[:external] = true} #mark as external explicitly

    @loProfile = options[:lo_profile] || {}

    I18n.locale = :en

    #3. Response
    respond_to do |format|
      format.any {
        render "los_profile/show", :layout => "container", :formats => ["html"]
      }
    end
  end


  private

  def get_lo_profile_from_session
    Session.getOrCreateUserData(session.id).getUserData["last_profile_los_api"]
  end

  def store_lo_profile_in_session(loProfile)
    sessionRecord = Session.getOrCreateUserData(session.id)
    userData = sessionRecord.getUserData
    userData["last_profile_los_api"] = loProfile
    sessionRecord.updateUserData(userData)
  end

end