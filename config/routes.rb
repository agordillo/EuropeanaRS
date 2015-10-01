Rails.application.routes.draw do

  root "home#index"

  resources :los

  match '/search', to: 'search#search', via: [:get, :post]
  
end
