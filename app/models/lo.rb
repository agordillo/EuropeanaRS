class Lo < ActiveRecord::Base
  validates :id_europeana, :presence => true, :uniqueness => true
  validates :europeana_metadata, :presence => true
  validates :url, :presence => true, :uniqueness => true

  before_validation :parseMetadata

  def parseMetadata
    europeanaItem = JSON.parse(self.europeana_metadata) rescue nil
    return if europeanaItem.nil?
    self.id_europeana = europeanaItem["id"]
    self.url = europeanaItem["guid"]
    self.title = europeanaItem["title"].first
    self.description = europeanaItem["dcDescription"].first
    self.language = europeanaItem["language"].first
    self.thumbnail_url = europeanaItem["edmPreview"].first
    self.year = europeanaItem["year"].first.to_i
    self.metadata_quality = europeanaItem["europeanaCompleteness"]
  end

end