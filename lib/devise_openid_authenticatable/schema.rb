Devise::Schema.class_eval do
  def openid_authenticatable
    if respond_to?(:apply_devise_schema)
      apply_devise_schema :identity_url, String
    else
      apply_schema :identity_url, String
    end
  end
end