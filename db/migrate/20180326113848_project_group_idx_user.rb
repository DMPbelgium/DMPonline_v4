class ProjectGroupIdxUser < ActiveRecord::Migration
  def up

    unless index_exists? :project_groups, [:project_id, :user_id]

      add_index :project_groups, [ :project_id, :user_id ], :unique => true

    end

  end

  def down

    if index_exists? :project_groups, [:project_id, :user_id]

      remove_index :project_groups, [:project_id, :user_id]

    end

  end
end
