require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EuropeanaRS
  class Application < Rails::Application

    #Automatically connect to the database when a rails console is started
    console do
        ActiveRecord::Base.connection
    end

    #Load EuropeanaRS configuration
    #Accesible here: EuropeanaRS::Application::config.APP_CONFIG
    config.APP_CONFIG = YAML.load_file("config/application_config.yml")[ENV["RAILS_ENV"] || "development"]

    config.domain = (config.APP_CONFIG["domain"] || "localhost:3000")

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # I18n (http://guides.rubyonrails.org/i18n.html)
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.i18n.available_locales = [config.i18n.default_locale, :es]
    # I18n fallbacks: rails will fallback to config.i18n.default_locale translation
    config.i18n.fallbacks = true

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    #Require core extensions
    Dir[File.join(Rails.root, "lib", "core_ext", "*.rb")].each {|l| require l }
  end
end
