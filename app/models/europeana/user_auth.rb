class Europeana::UserAuth < ActiveRecord::Base
  self.table_name = "europeana_user_auths"

  validates :public_key, :presence => true, :uniqueness => true
  validates :private_key, :presence => true

  belongs_to :user
end