class PlansController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  skip_load_and_authorize_resource :only => [:edit,:export,:status]

	# GET /plans/1/edit
	def edit

    @plan = Plan.includes(
      {
        :version => {
          :sections => {
            :questions => [:suggested_answers,:question_format,:options,:themes,:guidances]
          }
        }
      }
    ).find(params[:id])

    authorize! :edit, @plan

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
    @plan = Plan.includes(
      {
        :answers => [:options,:user]
      },
      {
        :version => {
          :sections => {
            :questions => [
              :question_format
            ]
          }
        }
      }
    ).find(params[:id])

    authorize! :status, @plan

		respond_to do |format|
			format.json { render json: @plan.status }
		end
	end

	def section_answers
		respond_to do |format|
			format.json { render json: @plan.section_answers(params[:section_id]) }
		end
	end

#	def locked
#		respond_to do |format|
#			format.json { render json: @plan.locked(params[:section_id],current_user.id) }
#		end
#	end

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
    st = nil
    Plan.transaction do
		  st = @plan.lock_section(params[:section_id], current_user.id)
    end
    render :json => st
	end

	def unlock_section
    @plan.unlock_section(params[:section_id], current_user.id)
    render :json => { :status => "ok" }
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
    @plan = Plan.includes(
      {
        :answers => :options
      },
      {
        :version => {
          :sections => :questions
        }
      }
    ).find(params[:id])

    authorize! :edit, @plan

		@exported_plan = ExportedPlan.new.tap do |ep|
			ep.plan_id = @plan.id
			ep.user_id = current_user.id
			ep.format = request.format.try(:symbol)
			plan_settings = @plan.settings(:export)

			Settings::Dmptemplate::DEFAULT_SETTINGS.each do |key, value|
				ep.settings(:export).send("#{key}=", plan_settings.send(key))
			end
		end

		@exported_plan.save! # FIXME: handle invalid request types without erroring?
    #sanitize file name (forward slashes are directory separators!)
		file_name = @exported_plan.project_name.gsub(/[\s\/]+/,"_")

		respond_to do |format|
      #format.html
      #format.xml
      #format.json
      #format.csv  { send_data @exported_plan.as_csv, filename: "#{file_name}.csv" }
      format.text { send_data @exported_plan.as_txt, filename: "#{file_name}.txt" }
			format.docx do
        #warning: do not use unsanitized version of project_name as base for this file,
        #as it uses this as a base for a temporary file, which, having a forward slash
        #,leads to a "file not found exception"
				file = Htmltoword::Document.create @exported_plan.html_for_docx, "doc"
				send_file file.path, :disposition => "attachment",:filename => file_name + ".docx"
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
