Rails.application.routes.draw do
  resources :messages, only: [:new, :create]
  resources :forms, only: [:new, :create]
end
