require 'devise/strategies/base'
require 'rack/openid'

base_class = begin
  Devise::Strategies::Authenticatable
rescue
  Devise::Strategies::Base
end

class Devise::Strategies::OpenidAuthenticatable < base_class

  def valid?
    valid_mapping? && ( provider_response? || identity_param? )
  end

  def authenticate!
    logger.debug("Authenticating with OpenID for mapping #{mapping.to}")

    if provider_response
      handle_response!
    else # Delegate authentication to Rack::OpenID by throwing a 401
      opts = { :identifier => params[scope]["identity_url"], :return_to => return_url, :trust_root => trust_root, :method => 'post' }
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
        resource = find_resource || build_resource || create_resource
        
        if resource
          begin
            update_resource!(resource)
          rescue
            fail! $!
          else
            success!(resource)
          end
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
    
    def find_resource
      mapping.to.find_by_identity_url(provider_response.identity_url)
    end
    
    def build_resource
      if mapping.to.respond_to?(:build_from_identity_url)
        mapping.to.build_from_identity_url(provider_response.identity_url)
      end
    end
    
    def create_resource
      if mapping.to.respond_to?(:create_from_identity_url)
        log.warn "DEPRECATION WARNING: create_from_identity_url is deprecated.  Please implement build_from_identity_url instead.  For more information, please see the devise_openid_authenticatable README."
        mapping.to.create_from_identity_url(provider_response.identity_url)
      end
    end

    def update_resource!(resource)
      if fields && resource.respond_to?(:openid_fields=)
        resource.openid_fields = fields
      end
      
      resource.save!
    end
    
    def fields
      return @fields unless @fields.nil?
      
      if axr = OpenID::AX::FetchResponse.from_success_response(provider_response)
        @fields = axr.data
      else
        provider_response.message.namespaces.each do |uri, ns_alias|
          if ns_alias.to_s == "sreg"
            @fields = provider_response.extension_response(uri, true)
            break
          end
        end
      end
      
      return @fields
    end

    def logger
      @logger ||= ((Rails && Rails.logger) || RAILS_DEFAULT_LOGGER)
    end
    
    def return_url
      return_to = URI.parse(request.url)
      scope_params = params[scope].inject({}) do |return_params, pair|
        param, value = pair
        return_params["#{scope}[#{param}]"] = value
        return_params
      end
      return_to.query = Rack::Utils.build_query(scope_params)
      return_to.to_s
    end

    def trust_root
      trust_root = URI.parse(request.url)
      trust_root.path = ""
      trust_root.query = nil
      trust_root.to_s
    end
end

Warden::Strategies.add :openid_authenticatable, Devise::Strategies::OpenidAuthenticatable
