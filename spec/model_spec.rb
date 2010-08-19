require 'spec_helper'

describe Devise::Models::OpenidAuthenticatable do

  it 'should respond to find_by_identity_url' do
    User.included_modules.should include(Devise::Models::OpenidAuthenticatable)
    User.should respond_to(:find_by_identity_url)
  end

end
