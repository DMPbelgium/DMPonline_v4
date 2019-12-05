# app/controllers/sessions_controller.rb
class SessionsController < Devise::SessionsController

	def create
		existing_user = User.find_by_email(params[:user][:email])

    unless existing_user.nil?
			#after authentication verify if session[:shibboleth] exists
      if !params[:shibboleth_data].nil? then
        existing_user.update_attributes(:shibboleth_id => session[:shibboleth_data][:uid])
      end
		end

    super
	end

	def destroy
    unless current_user.nil?
		  current_user.plan_sections.delete_all
    end
		super
	end

end
