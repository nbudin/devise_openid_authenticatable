require 'devise/version'

class CreateTables < ActiveRecord::Migration
  def self.openid_authenticatable_fields(t)
    if Devise::VERSION < "2.1"
      require 'devise/schema'
      t.openid_authenticatable
    else
      t.string :identity_url
    end
  end

  def self.rememberable_fields(t)
    if Devise::VERSION < "2.1"
      require 'devise/schema'
      t.rememberable
    else
      t.string :remember_token
      t.datetime :remember_created_at
    end
  end

  def self.up
    create_table :users do |t|
      openid_authenticatable_fields t
      rememberable_fields t
      t.string :email
      t.timestamps
    end
    
    create_table :database_users do |t|
      openid_authenticatable_fields t
      if Devise::VERSION < "2.1"
        t.database_authenticatable
      else
        t.string :email,              :null => false, :default => ""
        t.string :encrypted_password, :null => false, :default => ""
      end

      t.timestamps
    end
    
    create_table :legacy_users do |t|
      openid_authenticatable_fields t
      rememberable_fields t
      t.string :email
      t.timestamps
    end
  end

  def self.down
    drop_table :users
    drop_table :database_users
    drop_table :legacy_users
  end
end
