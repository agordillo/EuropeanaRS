class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_validation :fillSettings

  validates :name, :presence => true
  validates :language, :presence => true
  validate :checkSettings

  def checkSettings
    return errors[:base] << "User with empty settings" if self.settings.blank?

    begin
      parsedSettings = JSON.parse(self.settings)
    rescue
      return errors[:base] << "Settings: bad JSON file"
    end

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

  def parsedSettings
    (JSON.parse(self.settings)).recursive_symbolize_keys rescue User.defaultSettings
  end

  def self.defaultSettings
    default_user_settings = {
      :rs_weights => EuropeanaRS::Application::config.weights["default_rs_weights"],
      :los_weights => EuropeanaRS::Application::config.weights["default_los_weights"],
      :us_weights => EuropeanaRS::Application::config.weights["default_us_weights"]
    }
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

  private

  def fillSettings
    self.settings = User.defaultSettings.to_json if self.settings.blank?

    #Weights need normalization
    # parsedSettings["rs_weights"].each{|k,v| parsedSettings["rs_weights"][k] = ((v/rs_weights_sum.to_f).round(4))}
  end

end
