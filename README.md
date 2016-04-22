devise_openid_authenticatable [![Build Status](https://secure.travis-ci.org/nbudin/devise_openid_authenticatable.png)](http://travis-ci.org/nbudin/devise_openid_authenticatable)
==========================

Written by Nat Budin

devise_openid_authenticatable is [OpenID](http://openid.net) authentication support for
[Devise](http://github.com/plataformatec/devise) applications.  It is very thin and uses
[Rack::OpenID](http://github.com/josh/rack-openid) for most of the actual work.

Requirements
------------

- Devise 1.3 or higher
- rack-openid

Installation
------------

Add the following to your project's Gemfile:

    gem "devise_openid_authenticatable"

Then run `bundle install`.

Setup
-----

Once devise\_openid\_authenticatable is installed, add the following to your user model:

    devise :openid_authenticatable

You can also add other modules such as token_authenticatable, trackable, etc.  Database_authenticatable
should work fine alongside openid_authenticatable.

You'll also need to set up the database schema for this:

    create_table :users do |t|
      t.string :identity_url
    end

and, optionally, indexes:

    add_index :users, :identity_url, :unique => true

## Option 1: Configure a global identity_url
If the identity URL does not vary per user and you do not want to bother users with that you can configure a static identity URL through Devise.

In `config/initializers/devise.rb`, add:

```
Devise.setup do |config|
  config.openid_authenticatable do |openid|
    openid.identity_url = 'http://foobar.com'
  end
end
```

## Option 2: Pass the identity_url along via the login form
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

## Rails 2
Finally, *Rails 2* users, you'll need to wire up Rack::OpenID in your Rails configuration:

    config.middleware.insert_before(Warden::Manager, Rack::OpenID)

(Rack::OpenID needs to come before Warden in the middleware stack so that by the time
devise_openid_authenticatable tries to authenticate the user, the OpenID response will
have already been decoded by Rack::OpenID.)

Automatically creating users
----------------------------

If you want to have users automatically created when a new OpenID identity URL is
successfully used to sign in, you can implement a method called "build_from_identity_url"
to your user model class:

    class User < ActiveRecord::Base
      devise :openid_authenticatable

      def self.build_from_identity_url(identity_url)
        User.new(:identity_url => identity_url)
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

* Test on non-ActiveRecord ORMs
