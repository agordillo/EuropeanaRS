Rails.application.routes.draw do

  root "home#index"

  devise_for :users, controllers: { sessions: "users/sessions", registrations: "registrations" }
  resources :users
  match '/profile', to: 'users#profile', via: [:get]
  
  resources :los

  match '/search', to: 'search#search', via: [:get, :post]
  match '/change_locale', to: 'locales#change_locale', via: [:get]
  
  #Wildcard route (This rule should be placed the last)
  match '*path' => 'application#page_not_found', via: [:get]
end
