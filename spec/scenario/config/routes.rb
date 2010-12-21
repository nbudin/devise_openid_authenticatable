Rails.application.routes.draw do
  devise_for :users, :controllers => { :sessions => 'sessions' }
  devise_for :database_users, :controllers => { :sessions => 'sessions' }
  devise_for :legacy_users, :controllers => { :sessions => 'sessions' }
  root :to => "home#index"
end