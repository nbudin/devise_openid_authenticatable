if defined?(::Rails::Railtie)
  module DeviseOpenidAuthenticatable
    class Railtie < Rails::Railtie
      initializer "devise.openid_initialization" do |config|
        config.middleware.insert_before(Warden::Manager, Rack::OpenID)
      end
    end
  end
end
