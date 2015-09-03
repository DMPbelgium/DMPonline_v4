class PlansController < ApplicationController
	#Uncomment the line below in order to add authentication to this page - users without permission will not be able to add new plans
	#load_and_authorize_resource

	# GET /plans/1/edit
	def edit
		@plan = Plan.find(params[:id])
        
       
    if !user_signed_in? then
      respond_to do |format|
				format.html { redirect_to edit_user_registration_path }
			end
		elsif !@plan.readable_by(current_user.id) then
			respond_to do |format|
				format.html { redirect_to projects_url, notice: "This account does not have access to that plan." }
			end
		end
	end

	# PUT /plans/1
	# PUT /plans/1.json
	def update
		@plan = Plan.find(params[:id])
		if user_signed_in? && @plan.editable_by(current_user.id) then
			respond_to do |format|
			if @plan.update_attributes(params[:plan])
				format.html { redirect_to @plan, notice: 'Plan was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: "edit" }
				format.json { render json: @plan.errors, status: :unprocessable_entity }
			end
		end
    	else
			render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
    	end
  	end

  	# GET /status/1.json
	def status
  		@plan = Plan.find(params[:id])
  		if user_signed_in? && @plan.readable_by(current_user.id) then
			respond_to do |format|
				format.json { render json: @plan.status }
			end
		else
			render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
		end
	end

	def section_answers
  		@plan = Plan.find(params[:id])
  		if user_signed_in? && @plan.readable_by(current_user.id) then
			respond_to do |format|
				format.json { render json: @plan.section_answers(params[:section_id]) }
			end
		else
			render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
		end
	end

	def locked
  		@plan = Plan.find(params[:id])
  		if !@plan.nil? && user_signed_in? && @plan.readable_by(current_user.id) then
			respond_to do |format|
				format.json { render json: @plan.locked(params[:section_id],current_user.id) }
			end
		else
			render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
		end
	end

	def delete_recent_locks
		@plan = Plan.find(params[:id])
		if user_signed_in? && @plan.editable_by(current_user.id) then
			respond_to do |format|
				if @plan.delete_recent_locks(current_user.id)
					format.html { render action: "edit" }
					format.json { head :no_content }
				else
					format.html { render action: "edit" }
					format.json { render json: @plan.errors, status: :unprocessable_entity }
				end
			end
		else
			render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
		end
	end

	def unlock_all_sections
		@plan = Plan.find(params[:id])
		if user_signed_in? && @plan.editable_by(current_user.id) then
			respond_to do |format|
				if @plan.unlock_all_sections(current_user.id)
					format.html { render action: "edit" }
					format.json { head :no_content }
				else
					format.html { render action: "edit" }
					format.json { render json: @plan.errors, status: :unprocessable_entity }
				end
			end
		else
			render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
		end
	end

	def lock_section
		@plan = Plan.find(params[:id])
		if user_signed_in? && @plan.editable_by(current_user.id) then
			respond_to do |format|
				if @plan.lock_section(params[:section_id], current_user.id)
					format.html { render action: "edit" }
					format.json { head :no_content }
				else
					format.html { render action: "edit" }
					format.json { render json: @plan.errors, status: :unprocessable_entity }
				end
			end
		else
			render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
		end
	end

	def unlock_section
		@plan = Plan.find(params[:id])
		if user_signed_in? && @plan.editable_by(current_user.id) then
			respond_to do |format|
				if @plan.unlock_section(params[:section_id], current_user.id)
					format.html { render action: "edit" }
					format.json { head :no_content }
				else
					format.html { render action: "edit" }
					format.json { render json: @plan.errors, status: :unprocessable_entity }
				end
			end
		else
			render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
		end
	end

	def answer
  		@plan = Plan.find(params[:id])
  		if user_signed_in? && @plan.readable_by(current_user.id) then
			respond_to do |format|
				format.json { render json: @plan.answer(params[:q_id], false).to_json(:include => :options) }
			end
		else
			render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
		end
	end

	def warning
  		@plan = Plan.find(params[:id])
  		if user_signed_in? && @plan.readable_by(current_user.id) then
			respond_to do |format|
				format.json { render json: @plan.warning(params[:option_id]) }
			end
		else
			render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
		end
	end

	def export
		@plan = Plan.find(params[:id])

		if user_signed_in? && @plan.readable_by(current_user.id) then
			@exported_plan = ExportedPlan.new.tap do |ep|
				ep.plan = @plan
				ep.user = current_user
				ep.format = request.format.try(:symbol)
				plan_settings = @plan.settings(:export)

				Settings::Dmptemplate::DEFAULT_SETTINGS.each do |key, value|
					ep.settings(:export).send("#{key}=", plan_settings.send(key))
				end
			end

			@exported_plan.save! # FIXME: handle invalid request types without erroring?
			file_name = @exported_plan.project_name

			respond_to do |format|
                format.html
                format.xml
                format.json
                format.csv  { send_data @exported_plan.as_csv, filename: "#{file_name}.csv" }
                format.text { send_data @exported_plan.as_txt, filename: "#{file_name}.txt" }
				format.docx do
					file = Htmltoword::Document.create @exported_plan.html_for_docx, file_name
					send_file file.path, :disposition => "attachment"
				end
                format.pdf do
                    @formatting = @plan.settings(:export).formatting
                    $stderr.puts "render to #{file_name}"
                    $stderr.puts "foot text: #{ t('helpers.plan.export.pdf.generated_by') }"
                    $stderr.puts "formatting: #{@formatting[:margin][:bottom].inspect}"
                    render pdf: file_name,
			  	            margin: @formatting[:margin],
			  	            footer: {
			  	              center:    t('helpers.plan.export.pdf.generated_by'),
			  	              font_size: 8,
			  	              spacing:   (@formatting[:margin][:bottom] / 2) - 4,
			  	              right:     '[page] of [topage]'
			  	            }
			  end
			end
		elsif !user_signed_in? then
               respond_to do |format|
				format.html { redirect_to edit_user_registration_path }
			end
		elsif !@plan.editable_by(current_user.id) then
			respond_to do |format|
				format.html { redirect_to projects_url, notice: "This account does not have access to that plan." }
			end
		end
	end
end
