ENV["RAILS_ENV"] = "test"
$:.unshift File.dirname(__FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require "scenario/config/environment"
require "rails/test_help"
require 'rspec/rails'
require 'sham_rack'
require 'rots'

Webrat.configure do |config|
  config.mode = :rails
  config.open_error_files = false
end

RSpec.configure do |config|
  %i(controller view request).each do |type|
    config.include ::Rails::Controller::Testing::TestProcess,        type: type
    config.include ::Rails::Controller::Testing::TemplateAssertions, type: type
    config.include ::Rails::Controller::Testing::Integration,        type: type
  end if Rails.version >= '5'
  config.mock_with :mocha
  config.infer_spec_type_from_file_location!
end

# This is mostly copied in from bin/rots; they don't provide a single app class we could just reuse, unfortunately

rots_config = YAML.load(<<-ROTS_CONFIG)
# Default configuration file
identity: myid
sreg:
  nickname: jdoe
  fullname: John Doe
  email: jhon@doe.com
  dob: 1985-09-21
  gender: M
ROTS_CONFIG

rots_server_options = {
  :storage => File.join(File.dirname(__FILE__), 'scenario', 'tmp', 'rots')
}
rots_server = Rack::Builder.new do
  use Rack::Lint
  map ("/%s" % rots_config['identity']) do
    run Rots::IdentityPageApp.new(rots_config, rots_server_options)
  end
  map "/server" do
    run Rots::ServerApp.new(rots_config, rots_server_options)
  end
end

ShamRack.mount(rots_server, 'openid.example.org')

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
