class Log < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.integer :item_id
      t.string  :item_type
      t.string  :event
      t.text    :whodunnit
      t.integer :whodunnit_id
      t.text    :object
      t.timestamps
    end
    add_index :logs, :item_type
    add_index :logs, :whodunnit_id
    add_index :logs, :event
  end
end
