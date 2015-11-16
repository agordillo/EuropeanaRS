class AddEvaluations < ActiveRecord::Migration
  def change
    create_table :evaluations do |t|
      t.integer :user_id
      t.text :data
      t.string :status, :default => "0"
      t.timestamps null: false
    end
  end
end
