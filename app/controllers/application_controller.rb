class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
 
  def set_locale
    I18n.locale = extract_locale_from_params || extract_locale_from_user_profile || extract_locale_from_session || extract_locale_from_webclient || I18n.default_locale
  end

  def current_user_profile
    if user_signed_in?
      user_profile = current_user.profile
    else
      user_profile = {}
      user_profile[:language] = I18n.locale.to_s
      user_profile[:los] = Session.getUserData(session.id)["lo_profiles"] || []
    end
    
    user_profile
  end
  helper_method :current_user_profile

  def current_user_settings
    if user_signed_in?
      user_settings = current_user.parsedSettings
    else
      user_settings = session[:user_settings] || {}
    end
 
    User.defaultSettings.merge(user_settings)
  end
  helper_method :current_user_settings

  #Wildcard route rescue
  def page_not_found
    respond_to do |format|
      format.html {
        if request.path.include?("assets/") or request.xhr?
          render :text => 'Not Found', :status => '404'
        else
          flash[:alert] = I18n.t("dictionary.errors.page_not_found")
          redirect_to view_context.home_path, alert: flash[:alert]
        end
      }
      format.json {
        render json: I18n.t("dictionary.errors.page_not_found")
      }
    end
  end


  private

  def extract_locale_from_params
    params[:locale] if Utils.valid_locale?(params[:locale])
  end

  def extract_locale_from_user_profile
    current_user.ui_language if (user_signed_in? and Utils.valid_locale?(current_user.ui_language))
  end

  def extract_locale_from_session
    session[:locale] if Utils.valid_locale?(session[:locale])
  end

  def extract_locale_from_webclient
    client_locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    client_locale if Utils.valid_locale?(client_locale)
  end

end
