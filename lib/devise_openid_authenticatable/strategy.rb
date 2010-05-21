require 'devise/strategies/base'
require 'rack/openid'

module Devise
  module Strategies
    class OpenidAuthenticatable < Base
      def valid?
        env[Rack::OpenID::RESPONSE] || (mapping.to.respond_to?(:find_by_identity_url) && 
          params[scope] && !params[scope]["identity_url"].blank?)
      end

      def authenticate!
        RAILS_DEFAULT_LOGGER.info("Authenticating with OpenID for mapping #{mapping.to}")
        if resp = env[Rack::OpenID::RESPONSE]
          RAILS_DEFAULT_LOGGER.info "Attempting OpenID auth: #{env["rack.openid.response"].inspect}"
          case resp.status
          when :success
            u = mapping.to.find_by_identity_url(resp.identity_url)
            if u
              success!(u)
            elsif mapping.to.respond_to?(:create_from_identity_url)
              success!(mapping.to.create_from_identity_url(resp.identity_url))
            else
              fail!("This OpenID URL is not associated with any registered user")
            end
          when :cancel
            fail!("OpenID auth cancelled")
          when :failure
            fail!("OpenID auth failed")
          end
        else
          header_data = Rack::OpenID.build_header(:identifier => params[scope]["identity_url"])
          RAILS_DEFAULT_LOGGER.info header_data
          custom!([401, {
                Rack::OpenID::AUTHENTICATE_HEADER => header_data
              }, "Sign in with OpenID"])
        end
      end
    end
  end
end

Warden::Strategies.add(:openid_authenticatable, Devise::Strategies::OpenidAuthenticatable)
