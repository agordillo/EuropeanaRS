# encoding: utf-8

###############
# Class with utils for handling metadata records from Europeana
###############

class Europeana

  def self.saveRecord(europeanaItem)
    lo = Lo.new
    lo.europeana_metadata = europeanaItem.to_json rescue nil
    lo.save
  end

  #Translate ISO 639-1 codes to readable language names
  def self.getReadableLanguage(lanCode)
    case lanCode
      when "bg"
        "Bulgarian"
      when "cy"
        "Welsh"
      when "de"
        "German"
      when "en"
        "English"
      when "es"
        "Spanish"
      when "et"
        "Estonian"
      when "fr"
        "French"
      when "it"
        "Italian"
      when "lb"
        "Luxembourgish"
      when "lv"
        "Latvian"
      when "nl"
        "Dutch"
      when "pl"
        "Polish"
      when "pt"
        "Portuguese"
      when "ro"
        "Romanian"
      when "ru"
        "Russian"
      when "sr"
        "Serbian"
      else
        nil
      end
  end

end