class EuropeanaUserAuth < ActiveRecord::Base
  validates :public_key, :presence => true, :uniqueness => true
  validates :private_key, :presence => true
end