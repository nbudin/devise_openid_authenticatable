class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.openid_authenticatable
      t.rememberable
      t.string :email
      t.timestamps
    end
    
    create_table :database_users do |t|
      t.openid_authenticatable
      t.database_authenticatable
      t.timestamps
    end
    
    create_table :legacy_users do |t|
      t.openid_authenticatable
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
