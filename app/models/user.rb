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

    true
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
  end

end
