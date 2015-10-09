module ApplicationHelper
  
  def home_path
    return "/"
  end

  def options_for_select_languages_users
    I18n.available_locales.map{|lanCode|
      [Europeana.getReadableLanguage(lanCode.to_s),lanCode.to_s]
    }
  end

end
