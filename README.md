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

Finally, you'll need to add the following in your Rails configuration:

    config.middleware.use Rack::OpenID
    
which is the Rack middleware that actually does most of the heavy lifting here.

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
    
Ideally I'd like to add support for using sreg attributes here as well, to populate other
fields in the user table.

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
