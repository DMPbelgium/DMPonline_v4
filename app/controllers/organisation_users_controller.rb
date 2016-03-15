class OrganisationUsersController < ApplicationController
  before_filter :authenticate_user!

  #TODO: put access control in app/model/ability.rb
	def admin_index
    raise CanCan::AccessDenied.new unless user_signed_in? && current_user.is_org_admin?

		respond_to do |format|
			format.html # index.html.erb
		end
	end

end
