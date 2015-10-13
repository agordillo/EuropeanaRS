require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Europeana < OmniAuth::Strategies::OAuth2
      option :name, "Europeana"

      option :client_options, {
        :site => 'http://europeana.eu',
        :authorize_url => 'http://europeana.eu/api/oauth/authorize',
        :token_url => 'hhttp://europeana.eu/api/oauth/token'
      }

      uid { user_data['id'] }

      info do
        {
          'email' => user_data['email'],
          'name' => user_data['name']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def user_data
        access_token.options[:mode] = :query
        user_data ||= access_token.get('/me').parsed
      end

    end
  end
end