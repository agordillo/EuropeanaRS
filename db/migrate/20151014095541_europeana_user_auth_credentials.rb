class EuropeanaUserAuthCredentials < ActiveRecord::Migration
  def change
    create_table(:europeana_user_auths) do |t|
      t.text :public_key
      t.text :private_key
      t.text :session_id
      t.integer :user_id
      t.timestamps
    end
  end
end
