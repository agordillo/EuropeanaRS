class LocalesController < ActionController::Base

  def change_locale
    locale = params[:locale]
    unless I18n.available_locales.map(&:to_s).include? locale
      locale = I18n.default_locale.to_s
    end

    session[:locale] = locale
    
    redirect_to :back
  end

end