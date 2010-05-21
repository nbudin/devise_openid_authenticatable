require 'devise'

require 'devise_openid_authenticatable/schema'
require 'devise_openid_authenticatable/strategy'

Devise.add_module(:openid_authenticatable, 
  :strategy => true,
  :model => 'devise_openid_authenticatable/model',
  :route => :openid)
