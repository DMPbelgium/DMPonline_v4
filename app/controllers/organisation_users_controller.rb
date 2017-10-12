class OrganisationUsersController < ApplicationController
  before_filter :authenticate_user!

  #TODO: put access control in app/model/ability.rb
	def admin_index
    raise CanCan::AccessDenied.new unless user_signed_in? && current_user.is_org_admin?

    @users = current_user.organisation.users.all
		respond_to do |format|
			format.html
      format.csv {
        send_data(
          users_as_csv(@users),
          :filename => "users.csv"
        )
      }
		end
	end

private

  def users_as_csv(users)

    CSV.generate({ :col_sep => ";" }) { |csv|
      csv << [:email,:firstname,:surname,:orcid_id,:shibboleth_id,:last_sign_in_at,:num_projects]
      users.each { |u|
            csv << [
              u.email,
              u.firstname,
              u.surname,
              u.orcid_id,
              u.shibboleth_id,
              u.last_sign_in_at,
              u.project_groups.count
            ]
      }
    }

  end

end
