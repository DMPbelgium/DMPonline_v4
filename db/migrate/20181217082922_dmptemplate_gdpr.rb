class DmptemplateGdpr < ActiveRecord::Migration
  def up
    unless column_exists? :dmptemplates, :gdpr
      add_column :dmptemplates, :gdpr, :boolean, :null => false, :default => false
    end
    unless index_exists? :dmptemplates, :gdpr
      add_index :dmptemplates, :gdpr
    end
  end
  def down
    if column_exists? :dmptemplates, :gdpr
      remove_column :dmptemplates, :gdpr
    end
    if index_exists? :dmptemplates, :gdpr
      remove_index :dmptemplates, :gdpr
    end
  end
end
