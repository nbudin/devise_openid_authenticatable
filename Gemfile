source "http://rubygems.org"

gem "rack-openid", ">= 1.2.0"
gem "devise", ">= 1.0.6"

group :test do
  gem 'rails', '3.0.0'
  gem "rspec", "~> 2.3"
  gem "rspec-rails", "~> 2.3"
  gem "mocha"
  gem "sqlite3-ruby"
  gem "rots", :git => "http://github.com/roman/rots.git"
  gem "sham_rack"
  gem "webrat"

  if RUBY_VERSION.start_with? '1.9'
    gem "ruby-debug19"
  else
    gem "ruby-debug"
  end
end
