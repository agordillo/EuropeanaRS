module ApplicationHelper
  
  def home_path
    return "/"
  end

  def options_for_select_ui_languages
    I18n.available_locales.map{|lanCode|
      [Europeana.getReadableLanguage(lanCode.to_s),lanCode.to_s]
    }
  end

  def options_for_select_all_languages
    Europeana.getAllLanguages.map{|lanCode|
      [Europeana.getReadableLanguage(lanCode.to_s),lanCode.to_s]
    }
  end

end
