class RemoveSlugFromPhases < ActiveRecord::Migration
  def up
    if column_exists?(:phases,:slug)
      remove_column(:phases,:slug)
    end
    if index_exists?(:phases,:slug)
      remove_index(:phases,:slug)
    end
  end
  def down
    unless column_exists?(:phases,:slug)
      add_column :phases, :slug, :string
    end
    unless index_exists?(:phases,:slug)
      add_index :phases, :slug, unique: true
    end
  end
end
