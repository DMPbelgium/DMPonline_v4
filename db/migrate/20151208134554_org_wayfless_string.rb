class OrgWayflessString < ActiveRecord::Migration
  def change
    change_column :organisations, :wayfless_entity, :text
  end
end
