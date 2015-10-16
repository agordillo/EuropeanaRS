class AddPopularityFields < ActiveRecord::Migration
  def change
    add_column :los, :visit_count, :integer, :default => 0
    add_column :los, :like_count, :integer, :default => 0
  end
end
