class LoProfile < ActiveRecord::Base
  belongs_to :lo
  has_and_belongs_to_many :users

  validates :url, :presence => true
  validates :title, :presence => true


  #################
  # Getters
  #################

  def profile
    LoProfile.toProfile(self)
  end

  def readable_language
    Europeana.getReadableLanguage(self.language)
  end

  #################
  # LoProfile methods
  #################

  def external?
    self.lo_id.nil?
  end

  #################
  # Class Methods
  #################

  def self.fromLo(lo)
    where(lo_id: lo.id).first_or_create do |loProfile|
      loProfile.lo_id = lo.id

      loProfile.title = lo.title
      loProfile.description = lo.description
      loProfile.language = lo.language
      loProfile.year = lo.year

      loProfile.metadata_quality = lo.metadata_quality
      loProfile.popularity = lo.popularity

      loProfile.url = Rails.application.routes.url_helpers.lo_path(lo)
      loProfile.thumbnail_url = lo.thumbnail_url
    end
  end

  def self.fromLoProfile(loProfile)
    where(url: loProfile[:url]).first_or_create do |loProfileRecord|
      loProfileRecord.title = loProfile[:title]
      loProfileRecord.description = loProfile[:description]
      loProfileRecord.language = loProfile[:language]
      loProfileRecord.year = loProfile[:year]

      loProfileRecord.metadata_quality = loProfile[:metadata_quality]
      loProfileRecord.popularity = loProfile[:popularity]

      loProfileRecord.url = loProfile[:url]
      loProfileRecord.thumbnail_url = loProfile[:thumbnail_url]
    end
  end

  def self.toProfile(record)
    lo_profile = {}

    #Fields used to get similarity
    lo_profile[:title] = record.title
    lo_profile[:description] = record.description
    lo_profile[:language] = record.language
    lo_profile[:year] = record.year

    #Fields used for the RS
    lo_profile[:metadata_quality] = record.metadata_quality
    lo_profile[:popularity] = record.popularity

    #Fields used for visual representation
    lo_profile[:external] = (record.is_a? LoProfile and record.external?)
    lo_profile[:url] = (record.is_a? Lo) ? Rails.application.routes.url_helpers.lo_path(record) : record.url
    lo_profile[:thumbnail_url] = record.thumbnail_url

    lo_profile
  end

end