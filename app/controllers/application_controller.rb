class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
 
  def set_locale
    I18n.locale = params[:locale] || extract_locale_from_user_profile || extract_locale_from_session || extract_locale_from_webclient || I18n.default_locale
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
