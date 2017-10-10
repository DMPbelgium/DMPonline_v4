require 'email_validator'
class ProjectGroupsController < ApplicationController
  before_filter :authenticate_user!

	def create

    #filter params
    permitted = params.require(:project_group).permit( :email, :access_level, :project_id )

    #create new project group
		@project_group = ProjectGroup.new()

    #attach project
    @project_group.project = Project.find( permitted[:project_id] )

    #validate access level
    @project_group.access_level = permitted[:access_level].to_i

    #authorize project group
    authorize! :create, @project_group

		respond_to do |format|
      email = permitted[:email]

			if EmailValidator.valid?(email)

        user = User.find_by_email(email)

        if user.nil?

          user = User.new( :email => email )
          user.ensure_password

          #trigger validation to ensure organisation
          user.valid?

          if user.organisation.wayfless_entity.present?

            user.skip_confirmation!

          end

        end

        @project_group.user = user

        if @project_group.save

          UserMailer.sharing_notification(@project_group).deliver
          flash[:notice] = "User added to project"
          format.html { redirect_to :controller => 'projects', :action => 'share', :id => @project_group.project.slug }
          format.json { render json: @project_group, status: :created, location: @project_group }

        else

          flash[:alert] = @project_group.errors.full_messages
          format.html { redirect_to :controller => 'projects', :action => 'share', :id => @project_group.project.slug }
          format.json { render json: @project_group.errors, status: :unprocessable_entity }

        end

			else

				flash[:notice] = "Please enter a valid email address"
				format.html { redirect_to :controller => 'projects', :action => 'share', :id => @project_group.project.slug }
				format.json { render json: @project_group, status: :created, location: @project_group }

			end

		end
	end

	def update

    permitted = params.require(:project_group).permit(:access_level)

    @project_group = ProjectGroup.find(params[:id])

    @project_group.access_level = permitted[:access_level].to_i

    authorize! :update, @project_group

		respond_to do |format|

			if @project_group.save

				flash[:notice] = 'Sharing details successfully updated.'
				UserMailer.permissions_change_notification(@project_group).deliver
				format.html { redirect_to :controller => 'projects', :action => 'share', :id => @project_group.project.slug }
				format.json { head :no_content }

			else

				format.html { render action: "edit" }
				format.json { render json: @project_group.errors, status: :unprocessable_entity }

	    end

		end

  end

	def destroy

		@project_group = ProjectGroup.find(params[:id])

    authorize! :destroy, @project_group

		user = @project_group.user
		project = @project_group.project

		@project_group.destroy

		respond_to do |format|

			flash[:notice] = 'Access removed'
			UserMailer.project_access_removed_notification(user, project).deliver
			format.html { redirect_to :controller => 'projects', :action => 'share', :id => @project_group.project.slug }
			format.json { head :no_content }

		end

	end

end
