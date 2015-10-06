class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
 
  def set_locale
    I18n.locale = params[:locale] || extract_locale_from_user_profile || extract_locale_from_session || extract_locale_from_webclient || I18n.default_locale
  end

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

  def extract_locale_from_user_profile
    nil
  end

  def extract_locale_from_session
    session[:locale]
  end

  def extract_locale_from_webclient
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  end

end
