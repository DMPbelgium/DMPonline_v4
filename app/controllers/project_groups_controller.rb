class ProjectGroupsController < ApplicationController

	def create
		@project_group = ProjectGroup.new(params[:project_group])
		access_level = params[:project_group][:access_level].to_i
		if access_level >= 3 then
  		@project_group.project_administrator = true
  	end
  	if access_level >= 2 then
  		@project_group.project_editor = true
  	end

    authorize! :create, @project_group

		respond_to do |format|
			if params[:project_group][:email].present? && params[:project_group][:email].length > 0 then
				message = 'User added to project'
				if @project_group.save
					if @project_group.user.nil? then
						if User.find_by_email(params[:project_group][:email]).nil? then
							User.invite!(:email => params[:project_group][:email])
							message = 'Invitation issued successfully.'
							@project_group.user = User.find_by_email(params[:project_group][:email])
							@project_group.save
						else
							@project_group.user = User.find_by_email(params[:project_group][:email])
							@project_group.save
							UserMailer.sharing_notification(@project_group).deliver
							logger.debug("Email sent from here?")
						end
					else
						UserMailer.sharing_notification(@project_group).deliver
						logger.debug("Email sent from there?")
					end
					flash[:notice] = message
					format.html { redirect_to :controller => 'projects', :action => 'share', :id => @project_group.project.slug }
					format.json { render json: @project_group, status: :created, location: @project_group }
				else
					format.html { render action: "new" }
					format.json { render json: @project_group.errors, status: :unprocessable_entity }
				end
			else
				flash[:notice] = "Please enter an email address"
				format.html { redirect_to :controller => 'projects', :action => 'share', :id => @project_group.project.slug }
				format.json { render json: @project_group, status: :created, location: @project_group }
			end
		end
	end

	def update
    @project_group = ProjectGroup.find(params[:id])
    access_level = params[:project_group][:access_level].to_i
		if access_level >= 3 then
  			@project_group.project_administrator = true
  	else
  		@project_group.project_administrator = false
  	end
    if access_level >= 2 then
  	  @project_group.project_editor = true
    else
  	  @project_group.project_editor = false
    end

    authorize! :update, @project_group

		respond_to do |format|
			if @project_group.update_attributes(params[:project_group])
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
