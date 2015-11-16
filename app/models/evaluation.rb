class Evaluation < ActiveRecord::Base
  validates :user_id, :presence => true, :uniqueness => true
  validates :data, :presence => true
  validates_inclusion_of :status, :in => ["0","1","2","Finished"], :allow_nil => false

  belongs_to :user
end