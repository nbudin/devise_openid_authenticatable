require 'devise_openid_authenticatable/controller'

if defined?(::Rails::Railtie)
  module DeviseOpenidAuthenticatable
    class Railtie < Rails::Railtie
      initializer "devise.openid_initialization" do |config|
        config.middleware.insert_before(Warden::Manager, Rack::OpenID)
      end
      
      initializer "devise_openid_authenticatable.controller" do
        ActionController::Base.send(:include, DeviseOpenidAuthenticatable::Controller)
      end
    end
  end
end
