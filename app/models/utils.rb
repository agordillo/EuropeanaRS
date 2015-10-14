class Utils

  def self.valid_locale?(locale)
    !locale.blank? and I18n.available_locales.map(&:to_s).include? locale
  end

end
