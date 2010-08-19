require File.expand_path('../boot', __FILE__)

require "rails/all"
Bundler.require :default, Rails.env

require "devise"
require "devise_openid_authenticatable"

Devise.setup do |config|
  require "devise/orm/active_record"
end

module Scenario
  class Application < Rails::Application
    config.active_support.deprecation = :stderr
    config.middleware.insert_before(Warden::Manager, Rack::OpenID)
  end
end
