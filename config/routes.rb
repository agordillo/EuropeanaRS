Rails.application.routes.draw do

  root "home#index"

  devise_for :users, controllers: { sessions: "users/sessions", registrations: "users/registrations", :omniauth_callbacks => "users/omniauth_callbacks" }
  devise_scope :user do get "/users/sign_in/europeana/" => 'users/sessions#new_europeana' end
  devise_scope :user do post "/users/sign_in/europeana/" => 'users/sessions#create_europeana' end

  resources :users
  match '/profile', to: 'users#show', via: [:get]
  match '/account', to: 'users#show', via: [:get]
  match '/settings', to: 'users#settings', via: [:get]
  match '/settings', to: 'users#update_settings', via: [:post]
  match '/favorites', to: 'users#favorites', via: [:get]
  match '/api_keys', to: 'users#akeys', via: [:get]
 
  resources :apps
  
  resources :los do
    get 'like', on: :member
  end

  match '/search', to: 'search#search', via: [:get, :post]
  match '/change_locale', to: 'locales#change_locale', via: [:get]

  match '/api', to: 'recommender_system#api', via: [:post]
  match '/los_api', to: 'los_api#api', via: [:get, :post]

  #App users REST API
  post '/api/app_users', to: 'recommender_system#create_app_user'
  match '/api/app_users/:id', to: 'recommender_system#update_app_user', via: [:post, :put, :options]
  delete '/api/app_users/:id', to: 'recommender_system#destroy_app_user', via: [:delete, :options]
  
  #Wildcard route (This rule should be placed the last)
  match "*not_found", :to => 'application#page_not_found', via: [:get]
end
