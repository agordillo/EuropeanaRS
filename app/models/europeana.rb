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
  def self.getReadableLanguage(lanCode="")
    I18n.t("languages." + lanCode, :default => lanCode);
  end

end