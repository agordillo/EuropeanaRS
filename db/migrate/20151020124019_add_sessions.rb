class AddSessions < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.text :session_id
      t.text :data
      t.timestamps null: false
    end
    add_index :sessions, :session_id, :unique => true
    add_index :sessions, :updated_at
  end
end
