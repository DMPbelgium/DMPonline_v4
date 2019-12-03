class CreateRestUsers < ActiveRecord::Migration
  def change
    create_table :rest_users do |t|
      t.string :code, index: true
      t.string :token
      t.references :organisation, index: true, :null => false, foreign_key: true
      t.timestamps
    end
  end
end
