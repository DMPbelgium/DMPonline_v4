class MoveOrganisation < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.select_all("select * from user_org_roles") do |user_org_role|

      user_id = user_org_role["user_id"]
      organisation_id = user_org_role["organisation_id"]

      user = user_id.nil? ? nil : User.find( user_id )
      organisation = organisation_id.nil? ? nil : Organisation.find( organisation_id )

      if organisation && user
        user[:organisation_id] = organisation.id
        $stderr.puts "user #{user.email} has organisation_id #{organisation.id}"
        user.save
      end

    end
    drop_table :user_org_roles
    drop_table :user_role_types
  end
  def down
  end
end
