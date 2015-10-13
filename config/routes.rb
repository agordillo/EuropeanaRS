Rails.application.routes.draw do

  root "home#index"

  devise_for :users, controllers: { sessions: "users/sessions", registrations: "users/registrations", :omniauth_callbacks => "users/omniauth_callbacks" }

  resources :users
  match '/profile', to: 'users#profile', via: [:get]
  match '/account', to: 'users#profile', via: [:get]
  match '/settings', to: 'users#settings', via: [:get]
  match '/settings', to: 'users#update_settings', via: [:post]
  match '/favorites', to: 'users#favorites', via: [:get]
  match '/api_keys', to: 'users#akeys', via: [:get]

  resources :los

  match '/search', to: 'search#search', via: [:get, :post]
  match '/change_locale', to: 'locales#change_locale', via: [:get]
  
  #Wildcard route (This rule should be placed the last)
  match '*path' => 'application#page_not_found', via: [:get]
end
