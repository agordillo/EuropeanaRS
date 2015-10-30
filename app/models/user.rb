class User < ActiveRecord::Base
  has_and_belongs_to_many :saved_items, :class_name => "Lo"
  has_and_belongs_to_many :saved_lo_profiles, :class_name => "LoProfile"
  has_many :apps

  acts_as_taggable

  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => EuropeanaRS::Application::config.omniauth_providers

  before_validation :fillPasswordFlag
  before_validation :fillLanguages
  before_validation :fillTags
  before_validation :fillSettings

  validates :name, :presence => true
  validates :ui_language, :presence => true
  validates :language, :presence => true
  validates_inclusion_of :ug_password_flag, :in => [true, false]
  validate :checkLanguages
  validate :checkTags
  validate :checkSettings


  #################
  # Getters
  #################

  def parsedSettings
    (JSON.parse(self.settings)).parse_for_rs rescue User.defaultSettings
  end

  def pastLos(n=nil)
    n = EuropeanaRS::Application::config.max_user_los unless n.is_a? Numeric
    all_lops = self.saved_lo_profiles
    pastLos = all_lops.where("lo_id is NOT null").last((n/2.to_f).round)
    nFill = (n-pastLos.length)
    pastLos += all_lops.limit(nFill).where("lo_id is NULL or lo_id not in (?)", pastLos.map{|loProfile| loProfile.lo_id}).order("RANDOM()") if nFill > 0
    pastLos.map{|loProfile| loProfile.profile}
  end

  def profile
    user_profile = {}
    user_profile[:language] = self.language
    user_profile[:los] = self.pastLos
    user_profile
  end


  #################
  # User methods
  #################

  def like(lo)
    if lo.is_a? Lo and !self.like?(lo)
      self.saved_items << lo
      loProfile = LoProfile.fromLo(lo)
      self.saved_lo_profiles << loProfile
      lo.update_like_count
    end
  end

  def dislike(lo)
    if lo.is_a? Lo and self.like?(lo)
      self.saved_items.delete(lo)
      loProfile = LoProfile.fromLo(lo)
      self.saved_lo_profiles.delete(loProfile)
      lo.update_like_count
    end
  end

  def like?(lo)
    self.saved_items.include?(lo)
  end

  def addEuropeanaUserSavedItems(europeanaUserSavedItems)
    return unless europeanaUserSavedItems.is_a? Array
    europeanaUserSavedItems = europeanaUserSavedItems.reject{|item| item["europeanaId"].blank?}
    ids = europeanaUserSavedItems.map{|item| item["europeanaId"]}
    Lo.where("id_europeana in (?)",ids).each do |lo|
      self.like(lo)
      ids.delete(lo.id_europeana)
    end
    #Add external LO profiles
    europeanaUserSavedItems.select{|item| ids.include?(item["europeanaId"])}.each do |item|
      loProfile = LoProfile.where(:repository => "Europeana", :id_repository => item["europeanaId"]).first
      loProfile = Europeana.createLoProfileFromMyEuropeanaItem(item) if loProfile.nil?
      if !loProfile.nil? and loProfile.persisted?
        self.saved_lo_profiles << loProfile unless self.saved_lo_profiles.include?(loProfile)
      end
    end
  end

  def addEuropeanaUserTags(tags)
    return unless tags.is_a? Array
    self.tag_list = self.tag_list + tags
    self.save
  end

  def resetSettings
    self.settings = User.defaultSettings.to_json
    self.save!
  end

  #################
  # Class methods
  #################

  def self.defaultSettings
    default_user_settings = {
      :rs_weights => EuropeanaRS::Application::config.weights[:default_rs],
      :los_weights => EuropeanaRS::Application::config.weights[:default_los],
      :us_weights => EuropeanaRS::Application::config.weights[:default_us],
      :rs_filters => EuropeanaRS::Application::config.filters[:default_rs],
      :los_filters => EuropeanaRS::Application::config.filters[:default_los],
      :us_filters => EuropeanaRS::Application::config.filters[:default_us]
    }
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      #Create user with data from the provide
      user.email = !auth.info.email.blank? ? auth.info.email : (auth.uid.to_s + "@" + auth.provider + ".com")
      user.password = Devise.friendly_token[0,20]
      user.name = auth.info.name
      user.language = I18n.locale.to_s
      user.ui_language = Utils.valid_locale?(user.language) ? user.language : I18n.locale.to_s
    end
  end

  def self.from_europeana_profile(europeanaProfile)
    user = User.new
    user.email = europeanaProfile["email"]
    user.password = Devise.friendly_token[0,20]
    user.name = europeanaProfile["userName"]
    user.language = Utils.getLanguageFromCountry(europeanaProfile["country"]) || I18n.locale.to_s
    user.ui_language = Utils.valid_locale?(user.language) ? user.language : I18n.locale.to_s
    user.provider = "Europeana"
    user.uid = "Europeana:" + user.email
    user.save
    user
  end


  private

  def fillPasswordFlag
    if self.new_record?
      if self.provider.blank? or self.uid.blank?
        self.ug_password_flag = true
      else
        #User registered from external provider (using OAuth2 or other authentication mechanisms)
        self.ug_password_flag = false
      end
    end
    true
  end

  def fillLanguages
    self.ui_language = I18n.locale.to_s unless Utils.valid_locale?(self.ui_language)
    self.language = self.ui_language if self.language.blank?
    true
  end

  def fillTags
    return true if self.tag_list.blank?

    tagsConfig = EuropeanaRS::Application::config.tags
    self.tag_list = self.tag_list.first(tagsConfig["maxTags"]) if self.tag_list.length > tagsConfig["maxTags"]

    tagsToDelete = []
    self.tag_list.each do |tag|
      tL = tag.length
      if (tL < tagsConfig["minLength"] || tL > tagsConfig["maxLength"])
        tagsToDelete << tag
        break
      end

      tagsConfig["tagSeparators"].each do |s|
        if tag.include?(s)
          tagsToDelete << tag
          break 
        end
      end
    end

    tagsToDelete.each do |tag|
      self.tag_list.delete(tag)
    end

    true
  end

  def fillSettings
    self.settings = (User.defaultSettings.recursive_merge(self.parsedSettings)).to_json
    true
  end

  def checkLanguages
    return errors[:base] << "Invalid user UI locale" unless Utils.valid_locale?(self.ui_language)
    true
  end

  def checkTags
    return true if self.tag_list.blank?

    tagsConfig = EuropeanaRS::Application::config.tags
    return errors[:base] << ("Tag limit is " + tagsConfig["maxTags"].to_s) if self.tag_list.length > tagsConfig["maxTags"]
    
    self.tag_list.each do |tag|
      tL = tag.length

      if (tL < tagsConfig["minLength"] || tL > tagsConfig["maxLength"])
        errors[:base] << ("Invalid tag length for tag '" + tag + "'") 
        break
      end

      tagsConfig["tagSeparators"].each do |s|
        if tag.include?(s)
          errors[:base] << ("Invalid tag '" + tag + "'")
          break 
        end
      end

      break unless errors[:base].blank?
    end

    return errors[:base] unless errors[:base].blank?

    true
  end

  def checkSettings
    return errors[:base] << "User with empty settings" if self.settings.blank?

    parsedSettings = JSON.parse(self.settings) rescue (return errors[:base] << "Settings: bad JSON file")

    #RS Weights
    rs_weights_validation = checkSettingHash(parsedSettings["rs_weights"],"weights",["los_score", "popularity_score", "quality_score", "us_score"])
    return errors[:base] << rs_weights_validation unless rs_weights_validation.blank?

    #LoS Weights
    los_weights_validation = checkSettingHash(parsedSettings["los_weights"],"weights",["title", "description", "language", "year"])
    return errors[:base] << los_weights_validation unless los_weights_validation.blank?

    #US Weights
    us_weights_validation = checkSettingHash(parsedSettings["us_weights"],"weights",["language", "los"])
    return errors[:base] << us_weights_validation unless us_weights_validation.blank?

    #RS Filters
    rs_filters_validation = checkSettingHash(parsedSettings["rs_filters"],"filters",["los_score", "popularity_score", "quality_score", "us_score"])
    return errors[:base] << rs_filters_validation unless rs_filters_validation.blank?

    #LoS Filters
    los_filters_validation = checkSettingHash(parsedSettings["los_filters"],"filters",["title", "description", "language", "year"])
    return errors[:base] << los_filters_validation unless los_filters_validation.blank?

    #US Filters
    us_filters_validation = checkSettingHash(parsedSettings["us_filters"],"filters",["language", "los"])
    return errors[:base] << us_filters_validation unless us_filters_validation.blank?

    true
  end

  def checkSettingHash(settingHash,settingFamily,validKeys)
    unless settingHash.blank?

      #Completeness
      unless (settingHash.keys.sort_by{|k| k} === validKeys.sort_by{|k| k})
        return "Setting value: bad structure or missing keys"
      end

      #Individual values
      unless settingHash.select{|k,v| !v.is_a? Numeric or v>1 or v<0}.length === 0
        return "Setting value: invalid numeric value"
      end

      if settingFamily == "weights"
        #Weights Sum value
        rs_weights_sum = settingHash.map{|k,v| v}.sum
        if rs_weights_sum != 1
          return "RS Weights: all weights need to sum 1"
        end
      end

    end
  end

end
