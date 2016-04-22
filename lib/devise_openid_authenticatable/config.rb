module DeviseOpenidAuthenticatable
  module Config

    mattr_accessor :identity_url

  end
end

module DeviseOpenidAuthenticatable
  module Configurable

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def openid_authenticatable
        yield DeviseOpenidAuthenticatable::Config
      end

    end

  end
end

Devise.send(:include, DeviseOpenidAuthenticatable::Configurable)
