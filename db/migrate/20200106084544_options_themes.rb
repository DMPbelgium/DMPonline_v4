class OptionsThemes < ActiveRecord::Migration

  def self.up
    create_table :options_themes, :id => false do |t|
      t.references :option, :null => false
      t.references :theme, :null => false
    end
    add_index :options_themes, [:option_id, :theme_id]
  end

  def self.down
    drop_table :options_themes
  end

end
