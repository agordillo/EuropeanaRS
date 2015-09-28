class Lo < ActiveRecord::Base
  validates :id_europeana, :presence => true, :uniqueness => true
  validates :europeana_metadata, :presence => true
  validates :url, :presence => true, :uniqueness => true
  validates :title, :presence => true

  before_validation :parseMetadata

  def parseMetadata
    europeanaItem = JSON.parse(self.europeana_metadata) rescue nil
    return if europeanaItem.nil?
    begin
      self.id_europeana = europeanaItem["id"]
      self.url = europeanaItem["guid"]
      self.title = europeanaItem["title"].first unless europeanaItem["title"].nil?
      self.description = europeanaItem["dcDescription"].first unless europeanaItem["dcDescription"].nil?
      self.language = europeanaItem["language"].first unless europeanaItem["language"].nil?
      self.thumbnail_url = europeanaItem["edmPreview"].first unless europeanaItem["edmPreview"].nil?
      self.year = europeanaItem["year"].first.to_i unless europeanaItem["year"].nil?
      self.metadata_quality = europeanaItem["europeanaCompleteness"]
    rescue => e
    end
  end

end