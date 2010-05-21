if ActionController::Routing.name =~ /ActionDispatch/
  # We're on Rails 3
  ActionDispatch::Routing::Mapper.class_eval do
    protected
  
    alias_method :devise_openid, :devise_session
  end
else
  # We're on Rails 2

  ActionController::Routing::RouteSet::Mapper.class_eval do
    protected

    alias_method :openid_authenticatable, :database_authenticatable
  end
end