class DatabaseUser < ActiveRecord::Base
  devise :database_authenticatable, :openid_authenticatable
  validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => true
  
  def self.build_from_identity_url(identity_url)
    new(:identity_url => identity_url)
  end

  def self.openid_required_fields
    ["http://axschema.org/contact/email"]
  end

  def openid_fields=(fields)
    self.email = fields["http://axschema.org/contact/email"].first
  end
end