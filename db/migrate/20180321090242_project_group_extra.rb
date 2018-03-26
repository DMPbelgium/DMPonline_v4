class ProjectGroupExtra < ActiveRecord::Migration
  def up

    unless column_exists? :project_groups, :project_pi
      add_column :project_groups, :project_pi, :boolean
    end
    unless column_exists? :project_groups, :project_gdpr
      add_column :project_groups, :project_gdpr, :boolean
    end

  end

  def down

    #remove columns with project_pi or project_gdpr
    ProjectGroup.delete_all("project_pi = 1 OR project_gdpr = 1")

    if column_exists? :project_groups, :project_pi
      remove_column :project_groups, :project_pi
    end
    if column_exists? :project_groups, :project_gdpr
      remove_column :project_groups, :project_gdpr
    end

  end
end
