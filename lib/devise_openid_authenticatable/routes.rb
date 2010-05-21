require 'action_dispatch/routing/mapper'

module ActionDispatch::Routing
  class Mapper
    protected
  
    def devise_openid(mapping, controllers)
      devise_session(mapping, controllers)
    end
  end
end