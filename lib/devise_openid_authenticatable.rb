require 'devise'

require 'devise_openid_authenticatable/config'
require 'devise_openid_authenticatable/railtie'
require 'devise_openid_authenticatable/schema'
require 'devise_openid_authenticatable/strategy'

Devise.add_module :openid_authenticatable,
  :strategy => true,
  :model => 'devise_openid_authenticatable/model',
  :controller => :sessions,
  :route => :session
