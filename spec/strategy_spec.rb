require 'spec_helper'

describe Devise::Strategies::OpenidAuthenticatable do
  include RSpec::Rails::RequestExampleGroup

  def openid_params
    {
      "openid.identity"=>identity,
      "openid.sig"=>"OWYQspA5zZhoqRFhfSMFX/hLkok=",
      "openid.return_to"=>"http://www.example.com/users/sign_in?_method=post",
      "openid.op_endpoint"=>"http://openid.example.org",
      "openid.mode"=>"id_res",
      "openid.response_nonce"=>"2010-01-11T00:00:00Zeru5O3ETpTNX0A",
      "openid.ns"=>"http://specs.openid.net/auth/2.0",
      "openid.ns.ext1"=>"http://openid.net/srv/ax/1.0",
      "openid.ext1.value.ext0"=>"dimitrij@example.com",
      "openid.ext1.type.ext0"=>"http://axschema.org/contact/email",
      "openid.assoc_handle"=>"AOQobUeSdDcZUnQEYna4AZeTREaJiCDoii26u_x7wdrRrU5TqkGaqq9N",
      "openid.claimed_id"=>identity,
      "openid.signed"=>"op_endpoint,claimed_id,identity,return_to,response_nonce,assoc_handle,ns.ext1,ext1.mode,ext1.type.ext0,ext1.value.ext0"
    }
  end

  def stub_completion
    ax_info  = mock('AXInfo', :data => { "http://axschema.org/contact/email" => ["dimitrij@example.com"] })
    OpenID::AX::FetchResponse.stubs(:from_success_response).returns(ax_info)

    endpoint = mock('EndPoint')
    endpoint.stubs(:claimed_id).returns(identity)
    success  = OpenID::Consumer::SuccessResponse.new(endpoint, OpenID::Message.new, "ANY")
    OpenID::Consumer.any_instance.stubs(:complete_id_res).returns(success)
  end

  def identity
    @identity || 'http://openid.example.org/myid'
  end

  before do
    User.create! do |u|
      u.identity_url = "http://openid.example.org/myid"
    end

    LegacyUser.create! do |u|
      u.identity_url = "http://openid.example.org/myid"
    end

    DatabaseUser.create! do |u|
      u.email = "dbuser@example.com"
      u.password = "password"
      u.identity_url = "http://openid.example.org/myid"
    end
  end

  after do
    User.delete_all
    LegacyUser.delete_all
    DatabaseUser.delete_all
  end

  describe "GET /protected/resource" do
    before { get '/' }

    it 'should redirect to sign-in' do
      response.should be_redirect
      response.should redirect_to('/users/sign_in')
    end
  end

  describe "GET /users/sign_in" do
    before { get '/users/sign_in' }

    it 'should render the page' do
      response.should be_success
      response.should render_template("sessions/new")
    end
  end

  describe "POST /users/sign_in (without a identity URL param)" do
    before { post '/users/sign_in' }

    it 'should render the sign-in form' do
      response.should be_success
      response.should render_template("sessions/new")
    end
  end

  describe "POST /users/sign_in (with an empty identity URL param)" do
    before { post '/users/sign_in', 'user' => { 'identity_url' => '' } }

    it 'should render the sign-in form' do
      response.should be_success
      response.should render_template("sessions/new")
    end
  end

  describe "POST /users/sign_in (with a valid identity URL param)" do
    before do
      Rack::OpenID.any_instance.stubs(:begin_authentication).returns([302, {'Location' => 'http://openid.example.org/server'}, ['']])
      post '/users/sign_in', 'user' => { 'identity_url' => 'http://openid.example.org/myid' }
    end

    it 'should forward request to provider' do
      response.should be_redirect
      response.should redirect_to('http://openid.example.org/server')
    end
  end

  describe "POST /users/sign_in (with rememberable)" do
    before do
      post '/users/sign_in', 'user' => { 'identity_url' => 'http://openid.example.org/myid', 'remember_me' => 1 }
    end

    it 'should forward request to provider, with params preserved' do
      response.should be_redirect
      redirect_uri = URI.parse(response.header['Location'])
      redirect_uri.host.should == "openid.example.org"
      redirect_uri.path.should match(/^\/server/)

      # Crack open the redirect URI and extract the return parameter from it, then parse it too
      req = Rack::Request.new(Rack::MockRequest.env_for(redirect_uri.to_s))
      return_req = Rack::Request.new(Rack::MockRequest.env_for(req.params['openid.return_to']))
      return_req.params['user']['remember_me'].to_i.should == 1
    end
  end

  describe "POST /users/sign_in (from OpenID provider, with failure)" do

    before do
      post '/users/sign_in', "openid.mode"=>"failure", "openid.ns"=>"http://specs.openid.net/auth/2.0", "_method"=>"post"
    end

    it 'should fail authentication with failure' do
      response.should be_success
      response.should render_template("sessions/new")
      flash[:alert].should match(/failed/i)
    end
  end

  describe "POST /users/sign_in (from OpenID provider, when cancelled failure)" do

    before do
      post '/users/sign_in', "openid.mode"=>"cancel", "openid.ns"=>"http://specs.openid.net/auth/2.0", "_method"=>"post"
    end

    it 'should fail authentication with failure' do
      response.should be_success
      response.should render_template("sessions/new")
      flash[:alert].should match(/cancelled/i)
    end
  end

  describe "POST /users/sign_in (from OpenID provider, success, user already present)" do

    before do
      stub_completion
      post '/users/sign_in', openid_params.merge("_method"=>"post")
    end

    it 'should accept authentication with success' do
      response.should be_redirect
      response.should redirect_to('http://www.example.com/')
      flash[:notice].should match(/success/i)
    end

    it 'should update user-records with retrieved information' do
      expect(User.count).to eq 1
      User.first.email.should == 'dimitrij@example.com'
    end
  end

  describe "POST /users/sign_in (from OpenID provider, success, rememberable)" do

    before do
      stub_completion
      post '/users/sign_in', openid_params.merge("_method"=>"post", "user" => { "remember_me" => 1 })
    end

    it 'should accept authentication with success' do
      response.should be_redirect
      response.should redirect_to('http://www.example.com/')
      flash[:notice].should match(/success/i)
    end

    it 'should update user-records with retrieved information and remember token' do
      expect(User.count).to eq 1
      User.first.email.should == 'dimitrij@example.com'
      User.first.remember_token.should_not be_nil
    end
  end

  describe "POST /users/sign_in (from OpenID provider, success, NOT rememberable)" do
    before do
      stub_completion
      post '/users/sign_in', openid_params.merge("_method"=>"post", "user" => { "remember_me" => 0 })
    end

    it 'should update user-records with retrieved information but not remember token' do
      expect(User.count).to eq 1
      User.first.email.should == 'dimitrij@example.com'
      User.first.remember_token.should be_nil
    end
  end

  describe "POST /users/sign_in (from OpenID provider, success, new user)" do

    before do
      @identity = 'http://openid.example.org/newid'
      stub_completion
      post '/users/sign_in', openid_params.merge("_method"=>"post")
    end

    it 'should accept authentication with success' do
      response.should be_redirect
      response.should redirect_to('http://www.example.com/')
      flash[:notice].should match(/success/i)
    end

    it 'should auto-create user-records (if supported)' do
      User.count.should eq 2
    end

    it 'should update new user-records with retrieved information' do
      User.order(:id).last.email.should == 'dimitrij@example.com'
    end
  end

  describe "POST /legacy_users/sign_in (from OpenID provider, success, new user)" do

    before do
      @previous_logger = Rails.logger
      @log_output = StringIO.new
      Rails.logger = Logger.new(@log_output)

      @identity = 'http://openid.example.org/newid'
      stub_completion
      post '/legacy_users/sign_in', openid_params.merge("_method"=>"post")
    end

    after do
      Rails.logger = @previous_logger
    end

    it 'should accept authentication with success' do
      response.should be_redirect
      response.should redirect_to('http://www.example.com/')
      flash[:notice].should match(/success/i)
    end

    it 'should auto-create user-records (if supported)' do
      LegacyUser.count.should eq 2
    end

    it 'should update new user-records with retrieved information' do
      LegacyUser.order(:id).last.email.should == 'dimitrij@example.com'
    end

    it 'should issue a deprecation warning' do
      @log_output.string.should =~ /DEPRECATION WARNING: create_from_identity_url/
    end
  end

  describe "POST /database_users/sign_in (using database authentication)" do

    before do
      post '/database_users/sign_in', :database_user => { :email => "dbuser@example.com", :password => "password" }
    end

    it 'should accept authentication with success' do
      response.should be_redirect
      response.should redirect_to('http://www.example.com/')
      flash[:notice].should match(/success/i)
    end

  end

  describe "POST /database_users/sign_in (using OpenID, begin_authentication)" do
    before do
      Rack::OpenID.any_instance.stubs(:begin_authentication).returns([302, {'Location' => 'http://openid.example.org/server'}, ['']])
      post '/database_users/sign_in', 'database_user' => { 'identity_url' => 'http://openid.example.org/myid' }
    end

    it 'should forward request to provider' do
      response.should be_redirect
      response.should redirect_to('http://openid.example.org/server')
    end
  end

  describe "POST /database_users/sign_in (using OpenID, from provider, existing user)" do
    before do
      stub_completion
      post '/database_users/sign_in', openid_params.merge("_method"=>"post")
    end

    it 'should accept authentication with success' do
      response.should be_redirect
      response.should redirect_to('http://www.example.com/')
      flash[:notice].should match(/success/i)
    end

    it 'should update user-records with retrieved information' do
      DatabaseUser.count.should eq 1
      DatabaseUser.first.email.should == 'dimitrij@example.com'
    end
  end

  describe "POST /database_users/sign_in (using OpenID, from provider, existing email)" do
    before do
      DatabaseUser.delete_all
      DatabaseUser.create! do |u|
        u.email = "dimitrij@example.com"
        u.password = "password"
      end

      stub_completion
      post '/database_users/sign_in', openid_params.merge("_method"=>"post")
    end

    it 'should fail to authenticate with existing email error' do
      response.should be_success
      response.should render_template("sessions/new")
      flash[:alert].should match(/email/i)
      DatabaseUser.count.should eq 1
    end
  end

  describe "POST /database_users/sign_in (using OpenID, from provider, forgery attempt)" do
    before do
      DatabaseUser.delete_all
      DatabaseUser.create! do |u|
        u.email = "dimitrij@example.com"
        u.password = "password"
        u.identity_url = "http://openid.example.org/different_id"
      end

      stub_completion
      post '/database_users/sign_in', openid_params.merge("_method"=>"post")
    end

    it 'should fail authentication with existing email error' do
      response.should be_success
      response.should render_template("sessions/new")
      flash[:alert].should match(/email/i)
    end
  end
end
