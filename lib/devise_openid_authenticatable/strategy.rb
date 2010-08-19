require 'devise/strategies/base'
require 'rack/openid'

module Devise
  module Strategies
    class OpenidAuthenticatable < Base

      def valid?
        valid_mapping? && ( provider_response? || identity_param? )
      end

      def authenticate!
        logger.debug("Authenticating with OpenID for mapping #{mapping.to}")

        if provider_response
          handle_response!
        else # Delegate authentication to Rack::OpenID by throwing a 401
          opts = { :identifier => params[scope]["identity_url"] }
          opts[:optional] = mapping.to.openid_optional_fields if mapping.to.respond_to?(:openid_optional_fields)
          opts[:required] = mapping.to.openid_required_fields if mapping.to.respond_to?(:openid_required_fields)
          custom! [401, { Rack::OpenID::AUTHENTICATE_HEADER => Rack::OpenID.build_header(opts) }, "Sign in with OpenID"]
        end
      end

      protected

        # Handles incoming provider response
        def handle_response!
          logger.debug "Attempting OpenID auth: #{provider_response.inspect}"

          case provider_response.status
          when :success
            resource = mapping.to.find_by_identity_url(provider_response.identity_url)
            if resource.nil? && mapping.to.respond_to?(:create_from_identity_url)
              resource = mapping.to.create_from_identity_url(provider_response.identity_url)
            end

            if resource
              update_resource!(resource)
              success!(resource)
            else
              fail! "This OpenID URL is not associated with any registered user"
            end

          when :cancel
            fail! "OpenID authentication cancelled"
          when :failure
            fail! "OpenID authentication failed"
          end
        end

      private

        def provider_response?
          !!provider_response
        end

        def provider_response
          env[Rack::OpenID::RESPONSE]
        end

        def valid_mapping?
          mapping.to.respond_to?(:find_by_identity_url)
        end

        def identity_param?
          params[scope].try(:[], 'identity_url').present?
        end

        def update_resource!(resource)
          return unless resource.respond_to?(:openid_fields=)

          fields = nil
          if axr = OpenID::AX::FetchResponse.from_success_response(provider_response)
            fields = axr.data
          else
            provider_response.message.namespaces.each do |uri, ns_alias|
              if ns_alias.to_s == "sreg"
                fields = provider_response.extension_response(uri, true)
                break
              end
            end
          end

          if fields
            resource.openid_fields = fields
            resource.save
          end
        end

        def logger
          @logger ||= ((Rails && Rails.logger) || RAILS_DEFAULT_LOGGER)
        end

    end
  end
end

Warden::Strategies.add :openid_authenticatable, Devise::Strategies::OpenidAuthenticatable
