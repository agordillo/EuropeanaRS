class App < ActiveRecord::Base
  belongs_to :user
  has_many :user_profiles

  before_validation :fillKeys

  validates :name, :presence => true
  validates :app_key, :presence => true
  validates :app_secret, :presence => true


  # Methods

  def reset_keys
    self.app_key = Devise.friendly_token[0,20]
    self.app_secret =  Devise.friendly_token[0,20]
  end


  private

  def fillKeys
    self.name = "Unnamed" if self.name.blank?
    self.app_key = Devise.friendly_token[0,20] if self.app_key.blank?
    self.app_secret =  Devise.friendly_token[0,20] if self.app_secret.blank?
    true
  end
end