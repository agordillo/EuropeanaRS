class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
 
  def set_locale
    I18n.locale = extract_locale_from_params || extract_locale_from_user_profile || extract_locale_from_session || extract_locale_from_webclient || I18n.default_locale
  end

  def current_user_profile
    user_profile = {}
    user_profile[:language] = (extract_locale_from_user_profile || I18n.locale.to_s)
    
    user_profile
  end
  helper_method :current_user_profile

  def current_user_settings
    user_settings = {}
    default_user_settings = {
      :rs_weights => EuropeanaRS::Application::config.weights[:default_rs_weights],
      :los_weights => EuropeanaRS::Application::config.weights[:default_los_weights],
      :us_weights => EuropeanaRS::Application::config.weights[:default_us_weights]
    }
    user_settings = default_user_settings.merge(user_settings)
    
    user_settings
  end
  helper_method :current_user_settings

  #Wildcard route rescue
  def page_not_found
    respond_to do |format|
      format.html {
        flash[:alert] = I18n.t("dictionary.errors.page_not_found")
        redirect_to view_context.home_path, alert: flash[:alert]
      }
      format.json {
        render json: I18n.t("dictionary.errors.page_not_found")
      }
    end
  end


  private

  def extract_locale_from_params
    params[:locale] if (!params[:locale].blank? and I18n.available_locales.map(&:to_s).include? params[:locale])
  end

  def extract_locale_from_user_profile
    current_user.language if (user_signed_in? and !current_user.language.blank?)
  end

  def extract_locale_from_session
    session[:locale]
  end

  def extract_locale_from_webclient
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  end

end
