class GuidancesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authorize_org_admin!

  # GET /guidances
  # GET /guidances.json
  def admin_index
    @guidances = Guidance
      .includes(
        :guidance_groups,
        :themes
      )
      .by_organisation(current_user.organisation_id)
      .sort {|a,b| b.updated_at <=> a.updated_at }
    @guidance_groups = GuidanceGroup
      .includes(
        :dmptemplates
      )
      .where(
        :organisation_id => current_user.organisation_id
      )


    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @guidances }
    end
  end

  # GET /guidances/1
  # GET /guidances/1.json
  def admin_show
    @guidance = Guidance.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @guidance }
    end
  end

  def admin_new
    @guidance = Guidance.new
    @dmptemplates = Dmptemplate
      .includes(
        {
          :phases => {
            :versions => {
              :sections => :questions
            }
          }
        }
      )
      .funders_and_own_templates(current_user.organisation_id)
    @phases = []
    @dmptemplates.each do |template|
      @phases += template.phases.sort {|a,b| a.number <=> b.number }
    end
    @versions = []
    @phases.each do |phase|
      @versions += phase.versions.sort {|a,b| a.title <=> b.title }
    end
    @sections = []
    @versions.each do |version|
      @sections += version.sections.sort {|a,b| a.number <=> b.number }
    end
    @questions = []
    @sections.each do |section|
      @questions += section.questions.sort {|a,b| a.number <=> b.number }
    end
    respond_to do |format|
      format.html
    end
  end

  #setup variables for use in the dynamic updating
  def update_phases
    # updates phases, versions, sections and questions based on template selected
    dmptemplate = Dmptemplate.find(params[:dmptemplate_id])
    # map to title and id for use in our options_for_select
    @phases = dmptemplate.phases.map{|a| [a.title, a.id]}.insert(0, "Select a phase")
    @versions = dmptemplate.versions.map{|s| [s.title, s.id]}.insert(0, "Select a version")
    @sections = dmptemplate.sections.map{|s| [s.title, s.id]}.insert(0, "Select a section")
    @questions = dmptemplate.questions.map{|s| [s.text, s.id]}.insert(0, "Select a question")

  end

 def update_versions
    # updates versions, sections and questions based on phase selected
    phase = Phase.find(params[:phase_id])
    # map to name and id for use in our options_for_select
    @versions = phase.versions.map{|s| [s.title, s.id]}.insert(0, "Select a version")
    @sections = phase.sections.map{|s| [s.title, s.id]}.insert(0, "Select a section")
    @questions = phase.questions.map{|s| [s.text, s.id]}.insert(0, "Select a question")
  end

  def update_sections
    # updates sections and questions based on version selected
    version = Version.find(params[:version_id])
    # map to name and id for use in our options_for_select
    @sections = version.sections.map{|s| [s.title, s.id]}.insert(0, "Select a section")
    @questions = version.questions.map{|s| [s.text, s.id]}.insert(0, "Select a question")
  end

  def update_questions
    # updates songs based on artist selected
    section = Section.find(params[:section_id])
    @questions = section.questions.map{|s| [s.text, s.id]}.insert(0, "Select a question")
  end


  # GET /guidances/1/edit
  def admin_edit
    @guidance = Guidance.find(params[:id])
    @dmptemplates = Dmptemplate.funders_and_own_templates(current_user.organisation_id)
    @phases = nil
    @dmptemplates.each do |template|
      if @phases.nil? then
        @phases = template.phases.find(:all,:order => 'number ASC')
      else
        @phases = @phases + template.phases.find(:all,:order => 'number ASC')
      end
    end
    @versions = nil
    @phases.each do |phase|
      if @versions.nil? then
        @versions = phase.versions.find(:all,:order => 'title ASC')
      else
        @versions = @versions + phase.versions.find(:all,:order => 'title ASC')
      end
    end
    @sections = nil
    @versions.each do |version|
      if @sections.nil? then
        @sections = version.sections.find(:all,:order => 'number ASC')
      else
        @sections = @sections + version.sections.find(:all,:order => 'number ASC')
      end
    end
    @questions = nil
    @sections.each do |section|
      if @questions.nil? then
        @questions = section.questions.find(:all,:order => 'number ASC')
      else
        @questions = @questions + section.questions.find(:all,:order => 'number ASC')
      end
    end
  end

  # POST /guidances
  # POST /guidances.json
  def admin_create
    @guidance = Guidance.new(params[:guidance])
    @guidance.text = params["guidance-text"]
    @guidance.question_id = params["question_id"]

    respond_to do |format|
      if @guidance.save
        format.html { redirect_to admin_show_guidance_path(@guidance), notice: I18n.t('org_admin.guidance.created_message') }
        format.json { render json: @guidance, status: :created, location: @guidance }
      else
        format.html { render action: "new" }
        format.json { render json: @guidance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /guidances/1
  # PUT /guidances/1.json
  def admin_update
    @guidance = Guidance.find(params[:id])

    @guidance.text = params["guidance-text"]

    @guidance.question_id = params["question_id"]

    respond_to do |format|
      if @guidance.update_attributes(params[:guidance])
        format.html { redirect_to admin_show_guidance_path(params[:guidance]), notice: I18n.t('org_admin.guidance.updated_message') }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @guidance.errors, status: :unprocessable_entity }
      end
    end
  end


  # DELETE /guidances/1
  # DELETE /guidances/1.json
  def admin_destroy
    @guidance = Guidance.find(params[:id])
    @guidance.destroy

    respond_to do |format|
      format.html { redirect_to admin_index_guidance_path }
      format.json { head :no_content }
    end
  end

private

  def authorize_org_admin!

    unless user_signed_in? && current_user.is_org_admin?

      raise CanCan::AccessDenied.new

    end

  end

end
