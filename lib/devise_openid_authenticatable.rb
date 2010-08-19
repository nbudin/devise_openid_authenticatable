require 'devise'

require 'devise_openid_authenticatable/schema'
require 'devise_openid_authenticatable/strategy'
require 'devise_openid_authenticatable/routes'

Devise.add_module :openid_authenticatable,
  :strategy => true,
  :model => 'devise_openid_authenticatable/model',
  :controller => :sessions,
  :route => :openid
