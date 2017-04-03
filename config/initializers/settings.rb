# Set up EuropeanaRS general settings not related with the recommender system
# Recommender System settings are handled in config/initializers/recommender_system.rb
# Config accesible in EuropeanaRS::Application::config

Rails.application.configure do
  config.demo_user_available = (Rails.env==="development" and ActiveRecord::Base.connection.table_exists?('users') and !User.where(:name => "Demo", :email => "demo@europeanars.com").first.nil?)
end