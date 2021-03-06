class LoProfile < ActiveRecord::Base
  belongs_to :lo
  has_and_belongs_to_many :users

  validates :repository, :presence => true
  validates :id_repository, uniqueness: { scope: :repository }, :presence => true
  validates :title, :presence => true
  validates :resource_type, :presence => true


  #################
  # Getters
  #################

  def profile(options={})
    LoProfile.toProfile(self,options)
  end

  def readable_language
    Utils.getReadableLanguage(self.language)
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

      loProfile.repository = "Europeana"
      loProfile.id_repository = lo.id_europeana

      loProfile.resource_type = lo.resource_type
      loProfile.title = lo.title
      loProfile.description = lo.description
      loProfile.language = lo.language
      loProfile.year = lo.year

      loProfile.quality = lo.metadata_quality
      loProfile.popularity = lo.popularity

      loProfile.url = Rails.application.routes.url_helpers.lo_path(lo)
      loProfile.thumbnail_url = lo.thumbnail_url
    end
  end

  def self.fromLoProfile(loProfile)
    where(repository: loProfile[:repository], id_repository: loProfile[:id_repository]).first_or_create do |loProfileRecord|
      loProfileRecord.repository = loProfile[:repository]
      loProfileRecord.id_repository = loProfile[:id_repository]

      loProfileRecord.resource_type = loProfile[:resource_type]
      loProfileRecord.title = loProfile[:title]
      loProfileRecord.description = loProfile[:description]
      loProfileRecord.language = loProfile[:language]
      loProfileRecord.year = loProfile[:year]

      loProfileRecord.quality = loProfile[:quality]
      loProfileRecord.popularity = loProfile[:popularity]

      loProfileRecord.url = loProfile[:url]
      loProfileRecord.thumbnail_url = loProfile[:thumbnail_url]
    end
  end

  def self.toProfile(record,options={})
    lo_profile = {}

    #Fields used to identify the profile
    lo_profile[:repository] = "Europeana"
    lo_profile[:id_repository] = record.respond_to?("id_europeana") ? record.id_europeana : record.id_repository

    #Fields used to get similarity
    lo_profile[:resource_type] = record.resource_type
    lo_profile[:title] = record.title
    lo_profile[:description] = record.description
    lo_profile[:language] = record.language
    lo_profile[:year] = record.year

    #Fields used for the RS
    lo_profile[:quality] = record.respond_to?("quality") ? record.quality : record.metadata_quality
    lo_profile[:popularity] = record.popularity

    #Fields used for visual representation
    if options[:external]
      lo_profile[:url] = record.url
    else
      lo_profile[:external] = (record.is_a? LoProfile and record.external?)
      lo_profile[:url] = (record.is_a? Lo) ? Rails.application.routes.url_helpers.lo_path(record) : record.url
    end
    lo_profile[:thumbnail_url] = record.thumbnail_url

    lo_profile
  end

end