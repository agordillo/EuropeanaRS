Rails.application.routes.draw do

  root "home#index"

  resources :los

  match '/search', to: 'search#search', via: [:get, :post]
  match '/change_locale', to: 'locales#change_locale', via: [:get]
  
end
