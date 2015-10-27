class UserProfile < ActiveRecord::Base
  belongs_to :user
  belongs_to :app
  has_and_belongs_to_many :lo_profiles

  validate :user_or_app

  def user_or_app
    if self.user_id.blank?
      return errors[:base] << "User id or App id is required for creating a user profile" if self.app_id.blank?
    else
      return errors[:base] << "Both User id and App id can't be specify for creating a user profile " unless self.app_id.blank?
    end
    true
  end


  #################
  # Getters
  #################

  def profile(options={})
    UserProfile.toProfile(self,options)
  end

  def readable_language
    Utils.getReadableLanguage(self.language)
  end

  #################
  # UserProfile methods
  #################

  def pastLos(n=nil)
    n = EuropeanaRS::Application::config.max_user_los unless n.is_a? Numeric
    all_lops = self.lo_profiles
    pastLos = all_lops.where("lo_id is NOT null").last((n/2.to_f).round)
    nFill = (n-pastLos.length)
    pastLos += all_lops.limit(nFill).where("lo_id is NULL or lo_id not in (?)", pastLos.map{|loProfile| loProfile.lo_id}).order("RANDOM()") if nFill > 0
    pastLos.map{|loProfile| loProfile.profile}
  end

  def external?
    self.user_id.nil?
  end

  def updateFromUserProfile(user_profile)
    user_profile ||= {}

    self.language = user_profile[:language]

    if self.save
      self.lo_profiles = []
      unless user_profile[:los].blank?
        user_profile[:los].each do |loProfile|
          loProfileRecord = LoProfile.fromLoProfile(loProfile)
          self.lo_profiles << loProfileRecord if loProfileRecord.persisted?
        end
      end
      true
    else
      false
    end
  end

  #################
  # Class Methods
  #################

  def self.fromUser(user)
    userProfile = where(user_id: user.id).first_or_create do |userProfile|
      userProfile.user_id = user.id
      userProfile.language = user.language
      userProfile.settings = user.settings
      userProfile.tags = user.tag_list.join(",")
    end
    userProfile.lo_profiles = user.saved_lo_profiles if userProfile.persisted?
    userProfile
  end

  def self.fromApp(app,userIdInApp,user_profile={})
    user_profile ||= {}
    userProfile = where(app_id: app.id, id_app: userIdInApp).first_or_create do |userProfile|
      userProfile.app_id = app.id
      userProfile.id_app = userIdInApp
      userProfile.language = user_profile[:language]
    end
    if !user_profile[:los].blank? and userProfile.lo_profiles.blank?
      user_profile[:los].each do |loProfile|
        loProfileRecord = LoProfile.fromLoProfile(loProfile)
        userProfile.lo_profiles << loProfileRecord if loProfileRecord.persisted?
      end
    end
    userProfile
  end

  def self.toProfile(record,options={})
    user_profile = {}
    user_profile[:language] = record.language
    user_profile[:los] = record.pastLos
    user_profile
  end

end