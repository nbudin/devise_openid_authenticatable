# -*- encoding: utf-8 -*-
require File.expand_path('../lib/devise_openid_authenticatable/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nat Budin"]
  gem.email         = ["natbudin@gmail.com"]
  gem.description   = %q{OpenID authentication module for Devise using Rack::OpenID}
  gem.summary       = %q{OpenID authentication for Devise}
  gem.homepage      = "https://github.com/nbudin/devise_openid_authenticatable"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "devise_openid_authenticatable"
  gem.require_paths = ["lib"]
  gem.version       = DeviseOpenidAuthenticatable::VERSION

  gem.required_ruby_version = '>= 2.0'

  gem.add_dependency "rack-openid", ">= 1.2.0"
  gem.add_dependency "devise", ">= 1.3"

  gem.add_development_dependency "rspec", "~> 2.3"
  gem.add_development_dependency "rspec-rails", "~> 2.3"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "sqlite3-ruby"
  gem.add_development_dependency "sham_rack"
  gem.add_development_dependency "webrat"
  gem.add_development_dependency 'roman-rots'
end
