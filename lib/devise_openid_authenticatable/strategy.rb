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
        logger.debug("Authenticating with OpenID for mapping #{mapping.to}")
        if resp = env[Rack::OpenID::RESPONSE]
          logger.debug "Attempting OpenID auth: #{env["rack.openid.response"].inspect}"
          case resp.status
          when :success
            u = mapping.to.find_by_identity_url(resp.identity_url)
            if u.nil? && mapping.to.respond_to?(:create_from_identity_url)
              u = mapping.to.create_from_identity_url(resp.identity_url)
            end
            
            if u
              if u.respond_to?("openid_fields=")
                openid_fields = parse_openid_fields(resp)
              
                if openid_fields
                  u.openid_fields = openid_fields
                  u.save
                end
              end
              
              success!(u)
            else
              fail!("This OpenID URL is not associated with any registered user")
            end
          when :cancel
            fail!("OpenID auth cancelled")
          when :failure
            fail!("OpenID auth failed")
          end
        else
          header_params = { :identifier => params[scope]["identity_url"] }
          header_params[:optional] = mapping.to.openid_optional_fields if mapping.to.respond_to?(:openid_optional_fields)
          header_params[:required] = mapping.to.openid_required_fields if mapping.to.respond_to?(:openid_required_fields)
          header_data = Rack::OpenID.build_header(header_params)
          logger.debug header_data
          custom!([401, {
                Rack::OpenID::AUTHENTICATE_HEADER => header_data
              }, "Sign in with OpenID"])
        end
      end
      
      private
      def parse_openid_fields(resp)
        openid_fields = nil
        axr = OpenID::AX::FetchResponse.from_success_response(resp)
        if axr
          openid_fields = axr.data
        else
          resp.message.namespaces.each do |uri, ns_alias|
            if ns_alias.to_s == "sreg"
              openid_fields = resp.extension_response(uri, true)
              break
            end
          end
        end
        
        return openid_fields
      end
      
      def logger
        @logger ||= ((Rails && Rails.logger) || RAILS_DEFAULT_LOGGER)
      end
    end
  end
end

Warden::Strategies.add(:openid_authenticatable, Devise::Strategies::OpenidAuthenticatable)
