Rails.application.routes.draw do
  devise_for :users
  devise_for :database_users
  devise_for :legacy_users
  root :to => "home#index"
end