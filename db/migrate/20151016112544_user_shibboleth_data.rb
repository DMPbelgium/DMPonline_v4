class UserShibbolethData < ActiveRecord::Migration
  def up
    unless column_exists? :users,:shibboleth_data
      add_column :users,:shibboleth_data,:text
    end
  end

  def down
    if column_exists? :users,:shibboleth_data
      remove_column :users,:shibboleth_data
    end
  end
end
