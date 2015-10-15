class User < ActiveRecord::Base
  has_and_belongs_to_many :saved_items, :class_name => "Lo"

  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => EuropeanaRS::Application::config.omniauth_providers

  before_validation :fillPasswordFlag
  before_validation :fillLanguages
  before_validation :fillSettings

  validates :name, :presence => true
  validates :ui_language, :presence => true
  validates :language, :presence => true
  validates_inclusion_of :ug_password_flag, :in => [true, false]
  validate :checkLanguages
  validate :checkSettings


  #################
  # Getters
  #################

  def parsedSettings
    (JSON.parse(self.settings)).recursive_symbolize_keys rescue User.defaultSettings
  end

  def past_los
    []
  end

  def profile
    user_profile = {}
    user_profile[:language] = self.language
    user_profile[:los] = self.past_los
    user_profile
  end

  #################
  # User methods
  #################

  def like(lo)
    self.saved_items << lo unless (!lo.is_a? Lo or self.like?(lo))
  end

  def unlike(lo)
    self.saved_items.delete(lo) unless (!lo.is_a? Lo)
  end

  def like?(lo)
    self.saved_items.include?(lo)
  end

  def addEuropeanaUserSavedItems(europeanaUserSavedItems)
    return unless europeanaUserSavedItems.is_a? Array
    ids = europeanaUserSavedItems.map{|item| item["europeanaId"]}.compact
    Lo.where("id_europeana in (?)",ids).each do |lo|
      self.like(lo)
    end
  end

  #################
  # Class methods
  #################

  def self.defaultSettings
    default_user_settings = {
      :rs_weights => EuropeanaRS::Application::config.weights[:default_rs_weights],
      :los_weights => EuropeanaRS::Application::config.weights[:default_los_weights],
      :us_weights => EuropeanaRS::Application::config.weights[:default_us_weights]
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
    user.language = Europeana.getLanguageFromCountry(europeanaProfile["country"]) || I18n.locale.to_s
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

  def fillSettings
    self.settings = User.defaultSettings.to_json if self.settings.blank?
    true
  end

  def checkLanguages
    return errors[:base] << "Invalid user UI locale" unless Utils.valid_locale?(self.ui_language)
    true
  end

  def checkSettings
    return errors[:base] << "User with empty settings" if self.settings.blank?

    parsedSettings = JSON.parse(self.settings) rescue (return errors[:base] << "Settings: bad JSON file")

    #RS Weights
    rs_weights_validation = checkWeightsHash(parsedSettings["rs_weights"],["los_score", "popularity_score", "quality_score", "us_score"])
    return errors[:base] << rs_weights_validation unless rs_weights_validation.blank?

    #LoS Weights
    los_weights_validation = checkWeightsHash(parsedSettings["los_weights"],["title", "description", "language", "years"])
    return errors[:base] << los_weights_validation unless los_weights_validation.blank?

    #US Weights
    us_weights_validation = checkWeightsHash(parsedSettings["us_weights"],["language", "los"])
    return errors[:base] << us_weights_validation unless us_weights_validation.blank?

    true
  end

  def checkWeightsHash(weightsHash,validKeys)
    unless weightsHash.blank?

      #Completeness
      unless (weightsHash.keys.sort_by{|k| k} === validKeys.sort_by{|k| k})
        return "RS Weights: bad structure or missing weights"
      end

      #Individual values
      unless weightsHash.select{|k,v| !v.is_a? Numeric or v>1}.length === 0
        return "RS Weights: invalid weight value"
      end

      #Sum value
      rs_weights_sum = weightsHash.map{|k,v| v}.sum
      if rs_weights_sum != 1
        return "RS Weights: all weights need to sum 1"
      end
    end
  end

end
