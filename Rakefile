require 'rake'
require 'rake/rdoctask'
require 'rspec/mocks/version'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Default: run specs.'
task :default => :spec

desc 'Generate documentation for the devise_openid_authenticatable plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'devise_openid_authenticatable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "devise_openid_authenticatable"
    gemspec.summary = "OpenID authentication module for Devise"
    gemspec.description = "OpenID authentication module for Devise using Rack::OpenID"
    gemspec.email = "natbudin@gmail.com"
    gemspec.homepage = "http://github.com/nbudin/devise_openid_authenticatable"
    gemspec.authors = ["Nat Budin"]
    gemspec.add_runtime_dependency "devise", ">= 1.0.6"
    gemspec.add_runtime_dependency "rack-openid", ">= 1.1.2"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end
