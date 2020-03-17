class CreateWayflessEntities < ActiveRecord::Migration
  def up

    unless table_exists?(:wayfless_entities)

      create_table :wayfless_entities do |t|
        t.string :name, :null => false
        t.text :url, :null => false
        t.belongs_to :organisation, :null => false
        t.timestamps
      end

    end

    unless index_exists?(:wayfless_entities,:name)

      add_index :wayfless_entities, :name, :unique => true

    end

    unless index_exists?(:wayfless_entities,:url)

      #Mysql2::Error: BLOB/TEXT column 'url' used in key specification without a key length: CREATE UNIQUE INDEX `index_wayfless_entities_on_url` ON `wayfless_entities` (`url`)
      #for BLOB/TEXT you need to specify a length
      add_index :wayfless_entities, :url, :unique => true, :length => { :url => 255 }

    end

    ActiveRecord::Base.connection.select_all("select * from organisations").each do |org|

      next if org["wayfless_entity"].blank?

      we = WayflessEntity.new(
        :organisation_id => org["id"],
        :name => org["abbreviation"].nil? ? org["name"] : org["abbreviation"],
        :url  => org["wayfless_entity"]
      )

      if we.save

        $stdout.puts "migrated wayfless_entity from organisation #{org['name']} to wayfless_entities"

      else

        raise we.errors.messages.inspect

      end

    end

    if column_exists?(:organisations,:wayfless_entity)

      remove_column :organisations, :wayfless_entity

    end

  end
  def down

    unless column_exists?(:organisations, :wayfless_entity)

      add_column :organisations, :wayfless_entity, :text

    end

    ActiveRecord::Base.connection.select_all("select * from wayfless_entities").each do |we|

      org = Organisation.find(we["organisation_id"])
      org.wayfless_entity = we["url"]
      org.save

    end

    if table_exists?(:wayfless_entities)

      drop_table(:wayfless_entities)

    end

  end
end
