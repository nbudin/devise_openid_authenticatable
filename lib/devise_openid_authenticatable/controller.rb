module DeviseOpenidAuthenticatable
  module Controller
    extend ActiveSupport::Concern
    
    included do
      skip_before_filter :verify_authenticity_token, :if => :openid_provider_response?
    end
        
    protected
    def openid_provider_response?
      !!env[Rack::OpenID::RESPONSE]
    end
  end
end