class PlansController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

	# GET /plans/1/edit
	def edit
	end

	# PUT /plans/1
	# PUT /plans/1.json
	def update
		respond_to do |format|
			if @plan.update_attributes(params[:plan])
				format.html { redirect_to @plan, notice: 'Plan was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: "edit" }
				format.json { render json: @plan.errors, status: :unprocessable_entity }
			end
		end
  end

  # GET /status/1.json
	def status
		respond_to do |format|
			format.json { render json: @plan.status }
		end
	end

	def section_answers
		respond_to do |format|
			format.json { render json: @plan.section_answers(params[:section_id]) }
		end
	end

	def locked
		respond_to do |format|
			format.json { render json: @plan.locked(params[:section_id],current_user.id) }
		end
	end

	def delete_recent_locks
		respond_to do |format|
			if @plan.delete_recent_locks(current_user.id)
				format.html { render action: "edit" }
				format.json { head :no_content }
			else
				format.html { render action: "edit" }
				format.json { render json: @plan.errors, status: :unprocessable_entity }
			end
		end
	end

	def unlock_all_sections
		respond_to do |format|
			if @plan.unlock_all_sections(current_user.id)
				format.html { render action: "edit" }
				format.json { head :no_content }
			else
				format.html { render action: "edit" }
				format.json { render json: @plan.errors, status: :unprocessable_entity }
			end
		end
	end

	def lock_section
		respond_to do |format|
			if @plan.lock_section(params[:section_id], current_user.id)
				format.html { render action: "edit" }
				format.json { head :no_content }
			else
				format.html { render action: "edit" }
				format.json { render json: @plan.errors, status: :unprocessable_entity }
			end
		end
	end

	def unlock_section
		respond_to do |format|
			if @plan.unlock_section(params[:section_id], current_user.id)
				format.html { render action: "edit" }
				format.json { head :no_content }
			else
				format.html { render action: "edit" }
				format.json { render json: @plan.errors, status: :unprocessable_entity }
			end
		end
	end

	def answer
		respond_to do |format|
			format.json { render json: @plan.answer(params[:q_id], false).to_json(:include => :options) }
		end
	end

	def warning
		respond_to do |format|
			format.json { render json: @plan.warning(params[:option_id]) }
		end
	end

	def export
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
      #format.html
      #format.xml
      #format.json
      #format.csv  { send_data @exported_plan.as_csv, filename: "#{file_name}.csv" }
      format.text { send_data @exported_plan.as_txt, filename: "#{file_name}.txt" }
			format.docx do
				file = Htmltoword::Document.create @exported_plan.html_for_docx, file_name
				send_file file.path, :disposition => "attachment"
			end
      format.pdf do
        @formatting = @plan.settings(:export).formatting
        render pdf: file_name,
          encoding: "UTF-8",
			    margin: @formatting[:margin],
			  	footer: {
			  	  center:    t('helpers.plan.export.pdf.generated_by') + " - last updated at " + I18n.l( @plan.updated_at, :format => :custom ),
			  	  font_size: 8,
			  	  spacing:   (@formatting[:margin][:bottom] / 2) - 4,
			  	  right:     '[page] of [topage]'
			    }
		  end
    end
	end
end
