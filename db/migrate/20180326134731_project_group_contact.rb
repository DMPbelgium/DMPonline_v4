class ProjectGroupContact < ActiveRecord::Migration
  def up

    unless column_exists? :project_groups, :project_data_contact
      add_column :project_groups, :project_data_contact, :boolean
    end

  end

  def down

    ProjectGroup.delete_all("project_data_contact = 1")

    if column_exists? :project_groups, :project_data_contact
      remove_column :project_groups, :project_data_contact
    end

  end

end
