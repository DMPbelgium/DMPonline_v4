class RemoveOtherOrganisation < ActiveRecord::Migration
  def up
    if column_exists? :users, :other_organisation
      remove_column :users, :other_organisation
    end
  end
  def down
    unless column_exists? :users, :other_organisation
      add_column :users, :other_organisation, :string
    end
  end
end
