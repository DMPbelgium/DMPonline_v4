class OrganisationRemoveDomain < ActiveRecord::Migration
  def up
    if column_exists? :organisations, :domain
      remove_column :organisations, :domain
    end
  end
  def down
    unless column_exists? :organisations, :domain
      add_column :organisations, :domain, :string
    end
  end
end
