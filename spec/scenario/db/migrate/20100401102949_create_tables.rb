require 'devise/version'

def openid_authenticatable_fields(t)
  if Devise::VERSION < "2.1"
    require 'devise/schema'
    t.openid_authenticatable
  else
    t.string :identity_url
  end
end

class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      openid_authenticatable t
      t.rememberable
      t.string :email
      t.timestamps
    end
    
    create_table :database_users do |t|
      openid_authenticatable t
      t.database_authenticatable
      t.timestamps
    end
    
    create_table :legacy_users do |t|
      openid_authenticatable t
      t.rememberable
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
