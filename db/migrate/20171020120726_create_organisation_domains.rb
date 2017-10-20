class CreateOrganisationDomains < ActiveRecord::Migration
  def up
    create_table :organisation_domains do |t|
      t.string :name, :null => false
      t.belongs_to :organisation, :null => false
      t.timestamps
    end
    add_index :organisation_domains, :name, :unique => true

    ActiveRecord::Base.connection.select_all("select * from organisations").each do |org|
      next if org["domain"].blank?

      od = OrganisationDomain.new(
        :organisation_id => org["id"],
        :name => org["domain"]
      )
      if od.valid?
        od.save
      else
        raise od.errors.messages.inspect
      end
    end
  end
  def down
    remove_index :organisation_domains, :name
    drop_table :organisation_domains
  end
end
