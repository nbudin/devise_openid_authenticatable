devise_openid_authenticatable
==========================

Written by Nat Budin

devise_openid_authenticatable is [OpenID](http://openid.net) authentication support for
[Devise](http://github.com/plataformatec/devise) applications.  It is very thin and uses
[Rack::OpenID](http://github.com/josh/rack-openid) for most of the actual work.

Requirements
------------

- Devise 1.0.6 or later (including 1.1 versions)
- rack-openid

Installation
------------

    gem install --pre devise_openid_authenticatable
    
and add devise_openid_authenticatable to your Gemfile or config/environment.rb as a gem
dependency.

Example
-------

I've modified the devise_example application to work with this gem.  You can find the results
[here](http://github.com/nbudin/devise_openid_example).
    
Setup
-----

Once devise\_openid\_authenticatable is installed, add the following to your user model:

    devise :openid_authenticatable
    
You can also add other modules such as token_authenticatable, trackable, etc.  Database_authenticatable
should work fine alongside openid_authenticatable.

You'll also need to set up the database schema for this:

    create_table :users do |t|
      t.openid_authenticatable
    end

and, optionally, indexes:

    add_index :users, :identity_url, :unique => true
    
In addition, you'll need to modify sessions/new.html.erb (or the appropriate scoped view if you're
using those).  You need to add a field for identity_url, and remove username and password if you
aren't using database_authenticatable:

    <% form_for resource_name, resource, :url => session_path(resource_name) do |f| -%>
      <p><%= f.label :identity_url %></p>
      <p><%= f.text_field :identity_url %></p>

      <% if devise_mapping.rememberable? -%>
        <p><%= f.check_box :remember_me %> <%= f.label :remember_me %></p>
      <% end -%>

      <p><%= f.submit "Sign in" %></p>
    <% end -%>

Finally, you'll need to wire up Rack::OpenID in your Rails configuration.  The way to do this varies depending on which version of Rails you're using.  If you're on Rails 2.3 (and Devise 1.0), you must initialize it like this:

    require 'openid/store/memory'
    config.middleware.use "Rack::OpenID", OpenID::Store::Memory.new

(Specifying an OpenID store instance is necessary because Rails 2.3 reinitializes the middleware objects on each request, so in order to ensure that the stored OpenID data is persistent between subsequent requests, we initialize the Memory store upfront and pass in the same instance each time.  If you prefer to use a different store, such as the Memcached store, feel free to substitute in the appropriate class here.)

If you're using Rails 3, you'll need to do this instead, to ensure that Rack::OpenID sits above Warden in the Rack middleware stack:

    config.middleware.insert_before(Warden::Manager, Rack::OpenID)

Automatically creating users
----------------------------

If you want to have users automatically created when a new OpenID identity URL is
successfully used to sign in, you can implement a method called "create_from_identity_url"
to your user model class:

    class User < ActiveRecord::Base
      devise :openid_authenticatable
      
      def self.create_from_identity_url(identity_url)
        User.create(:identity_url => identity_url)
      end
    end
    
SReg and AX Extensions
----------------------

As of version 1.0.0.alpha4, devise_openid_authenticatable now supports the SReg (simple registration) and AX
(attribute exchange) extensions.  This allows OpenID providers to pass you additional user details, such as
name, email address, gender, nickname, etc.

To add SReg and AX support to your User model, you'll need to do two things: first, you need to specify what
fields you'd like to request from OpenID providers.  Second, you need to provide a method for processing
these fields during authentication.

To specify which fields to request, you can implement one (or both) of two class methods: 
openid_required_fields and openid_optional_fields.  For example:

    def self.openid_required_fields
      ["fullname", "email", "http://axschema.org/namePerson", "http://axschema.org/contact/email"]
    end
    
    def self.openid_optional_fields
      ["gender", "http://axschema.org/person/gender"]
    end

Required fields should be used for fields without which your app can't operate properly.  Optional fields
should be used for fields which are nice to have, but not necessary for your app.  Note that just because you
specify a field as "required" doesn't necessarily mean that the OpenID provider has to give it to you (for 
example, a provider might not have that field for its users).

In the above example, we're specifying both SReg fields (fullname, email, and gender) and the equivalent
AX fields (the ones that look like URLs).  A list of defined AX fields and their equivalent SReg fields can
be found at [http://www.axschema.org/types](http://www.axschema.org/types).  It is highly recommended to 
specify both AX and SReg fields, as both are implemented by different common OpenID providers.

Once a successful OpenID response comes back, you still need to process the fields that the provider returned
to your app.  To do that, implement an instance method called openid_fields=.  This method takes a hash that
maps each returned field to a string value.  For example:

    def openid_fields=(fields)
      fields.each do |key, value|
        # Some AX providers can return multiple values per key
        if value.is_a? Array
          value = value.first
        end
      
        case key.to_s
        when "fullname", "http://axschema.org/namePerson"
          self.name = value
        when "email", "http://axschema.org/contact/email"
          self.email = value
        when "gender", "http://axschema.org/person/gender"
          self.gender = value
        else
          logger.error "Unknown OpenID field: #{key}"
        end
      end
    end

See also
--------

* [OpenID](http://openid.net)
* [Rack::OpenID](http://github.com/josh/rack-openid)
* [Devise](http://github.com/plataformatec/devise)
* [Warden](http://github.com/hassox/warden)

TODO
----

* Add sreg attributes support
* Write test suite
* Test on non-ActiveRecord ORMs
