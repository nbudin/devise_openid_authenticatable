module Devise
  module Models
    module OpenidAuthenticatable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def find_by_identity_url(identity_url)
          where(:identity_url => identity_url).first
        end
      end
      
      module InstanceMethods
        def valid_for_authentication?
        end
      end
    end
  end
end
