class OrganisationGdpr < ActiveRecord::Migration
  def up
    #i.e. does an organisation want to see the menu "gdpr or not" during the creation of a plan?
    unless column_exists? :organisations, :gdpr
      add_column :organisations, :gdpr, :boolean, :null => false, :default => false
    end
    unless index_exists? :organisations, :gdpr
      add_index :organisations, :gdpr
    end
  end

  def down
    if column_exists? :organisations, :gdpr
      remove_column :organisations, :gdpr
    end
    if index_exists? :organisations, :gdpr
      remove_index :organisations, :gdpr
    end
  end
end
