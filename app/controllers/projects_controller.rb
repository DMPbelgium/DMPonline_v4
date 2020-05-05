class ProjectsController < ApplicationController
  before_filter :authenticate_user!
	before_filter :get_plan_list_columns, only: %i( index )

	# GET /projects
	# GET /projects.json
	def index
    authorize! :index, Project

		if (current_user.shibboleth_id.nil? || current_user.shibboleth_id.length == 0) && !cookies[:show_shib_link].nil? && cookies[:show_shib_link] == "show_shib_link" then
			flash.notice = "Would you like to #{view_context.link_to 'link your DMPonline account to your institutional credentials?', user_omniauth_shibboleth_path}".html_safe
		end

    @projects = Project
      .includes(
        { :project_groups => :user },
        { :plans => :answers },
        { :dmptemplate => :organisation }
      )
      .where(
        :id => current_user.project_groups.all.map(&:project_id).uniq
      )
      .order("updated_at DESC")
      .all()

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @projects }
		end
	end

	# GET /projects/1
	# GET /projects/1.json
	def show
		@project = find_project(
      params[:id],
      Project.includes(
        { :project_groups => :user },
        { :plans => :version },
        { :dmptemplate => :organisation }
      )
    )
    authorize! :show, @project

		@show_form = false
		if params[:show_form] == "yes" then
			@show_form = true
		end
		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @project }
		end
	end

	# GET /projects/new
	# GET /projects/new.json
	def new
    authorize! :new,Project
		@project = Project.new
		@project.organisation = current_user.organisation
		@funders = orgs_of_type(t('helpers.org_type.funder'), true)
		@institutions = orgs_of_type(t('helpers.org_type.institution'))
		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @project }
		end
	end

	# GET /projects/1/edit
     # Should this be removed?
	def edit
		@project = find_project(params[:id])
    authorize! :edit, @project
	end

	def share
		@project = find_project(
      params[:id],
      Project.includes(
        { :project_groups => :user }
      )
    )
    authorize! :share,@project
	end

	def export
		@project = find_project(
      params[:id],
      Project.includes(
        {
          :plans => {
            :version => {
              :sections => :questions
            }
          }
        }
      )
    )
    authorize! :export,@project
		respond_to do |format|
			format.html { render action: "export" }
		end
	end

	# POST /projects
	# POST /projects.json
	def create
    authorize! :create,Project

    gdpr = params[:project_gdpr].present? && params[:project_gdpr] == "true" ? true : false

		@project = Project.new(params[:project])

    #choose funder template
		if @project.dmptemplate.nil? && params[:project][:funder_id].present? && (funder = Organisation.where(:id => params[:project][:funder_id]).first) then

      funder_template = funder.dmptemplates.where(:gdpr => gdpr,:published => true).first

			if !(funder_template.nil?) then

				@project.dmptemplate = funder_template

			end

    #choose organisation template
		elsif @project.dmptemplate.nil? then

      org = @project.organisation
      org_template = org.nil? ? nil : org.dmptemplates.where(:gdpr => gdpr,:published => true).first

      #or choose default template when organisation template cannot be found
			if org.nil? || org_template.nil? then

        #sorry, no magic default for gdpr
        if !gdpr

				  @project.dmptemplate = Dmptemplate.where(:is_default => true,:published => true).first

        end

			else

				@project.dmptemplate = org_template

			end

		end

		#@project.title = I18n.t('helpers.project.my_project_name')+' ('+@project.dmptemplate.title+')'
		@project.assign_creator(current_user.id)
    @project.assign_pi(current_user.id)

    #"is_valid?" clears errors before validation, so we need to do this here, and then add own errors
    project_is_valid = @project.valid?

    #check gdpr inconsistencies
    if !(@project.dmptemplate.nil?) && @project.dmptemplate.gdpr != gdpr

      @project.errors[:base] << I18n.t("activerecord.errors.models.project.attributes.base.gdpr_diff")

    end

    #org must allow gdpr
    if gdpr

      #must be same org
      if @project.organisation_id != current_user.organisation_id

        @project.errors[:base] << I18n.t("activerecord.errors.models.project.attributes.base.gdpr_only_own_org")

      end
      #if dmptemplate is organisational, then it must be of the own org
      if !(@project.dmptemplate.nil?) && @project.dmptemplate.org_type == "Institution" && @project.dmptemplate.organisation_id != current_user.organisation_id

        @project.errors[:base] << I18n.t("activerecord.errors.models.project.attributes.base.gdpr_dmptemplate_only_own_org")

      end

    end

    project_is_valid = @project.errors.count == 0

		respond_to do |format|
			if project_is_valid
        @project.save({ :validate => false })
				format.html { redirect_to({:action => "show", :id => @project.id, :show_form => "yes"}, {:notice => I18n.t('helpers.project.success')}) }
				format.json { render json: @project, status: :created, location: @project }
			else
				format.html { redirect_to( {:action => "new"},{ :alert => @project.errors.full_messages } ) }
				format.json { render json: @project.errors, status: :unprocessable_entity }
			end
		end
	end

	# PUT /projects/1
	# PUT /projects/1.json
	def update
		@project = find_project(params[:id])
    authorize! :update,@project
		respond_to do |format|
			if @project.update_attributes(params[:project])
				format.html { redirect_to @project, notice: 'Project was successfully updated.' }
				format.json { head :no_content }
			else
				format.html {
          redirect_to(
            { :action => "show", :id => @project.id, :show_form => "yes" },
            { :alert => @project.errors.full_messages }
          )
        }
				format.json { render json: @project.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /projects/1
	# DELETE /projects/1.json
	def destroy
		@project = find_project(params[:id])
    authorize! :destroy,@project
		@project.destroy

		respond_to do |format|
			format.html { redirect_to projects_url }
			format.json { head :no_content }
		end
	end

  # GET /projects/possible_funders.json
  def possible_funders
    gdpr = params[:gdpr].present? && params[:gdpr] == "true" ? true : false
    funder_orgs = {}
    orgs_of_type(t('helpers.org_type.funder'), true).each do |org|
      next if org.dmptemplates.where(:gdpr => gdpr,:published => true).count <= 0
      funder_orgs[ org.id ] = org.name
    end
    respond_to do |format|
      format.json { render json: funder_orgs.to_json }
    end
  end

	# GET /projects/possible_templates.json
	def possible_templates
    gdpr = params[:gdpr].present? && params[:gdpr] == "true" ? true : false
    funder = nil
		if !params[:funder].nil? && params[:funder] != "" && params[:funder] != "undefined" then
			funder = Organisation.where(:id => params[:funder]).first
		end
    institution = nil
		if !params[:institution].nil? && params[:institution] != "" && params[:institution] != "undefined" then
			institution = Organisation.where(:id => params[:institution]).first
		end
		templates = {}
		unless funder.nil? then
			funder.published_templates.each do |t|
        next if t.gdpr != gdpr
				templates[t.id] = t.title
        templates[t.id] += " [GDPR]" if t.gdpr
			end
		end
		if templates.count == 0 && !institution.nil? then
			institution.published_templates.each do |t|
        next if t.gdpr != gdpr
				templates[t.id] = t.title
        templates[t.id] += " [GDPR]" if t.gdpr
			end
			institution.children.each do |o|
				o.published_templates.each do |t|
          next if t.gdpr != gdpr
					templates[t.id] = t.title
          templates[t.id] += " [GDPR]" if t.gdpr
				end
			end
		end
		respond_to do |format|
			format.json { render json: templates.to_json }
		end
	end

	def possible_guidance
		if !params[:template].nil? && params[:template] != "" && params[:template] != "undefined" then
			template = Dmptemplate.where(:id => params[:template]).first
		else
			template = nil
		end
		if !params[:institution].nil? && params[:institution] != "" && params[:institution] != "undefined" then
			institution = Organisation.where(:id => params[:institution]).first
		else
			institution = nil
		end
		excluded_orgs = orgs_of_type(t('helpers.org_type.funder')) + orgs_of_type(t('helpers.org_type.institution')) + Organisation.orgs_with_parent_of_type(t('helpers.org_type.institution'))
		guidance_groups = {}
		ggs = GuidanceGroup.guidance_groups_excluding(excluded_orgs)

		ggs.each do |gg|
			guidance_groups[gg.id] = gg.name
		end
		unless institution.nil? then
			optional_gg = GuidanceGroup.where("optional_subset =  ? && organisation_id = ?", true, institution.id)
			optional_gg.each do|optional|
				guidance_groups[optional.id] = optional.name
			end

			institution.children.each do |o|
				o.guidance_groups.each do |gg|
					include = false
					gg.guidances.each do |g|
						if g.dmptemplate.nil? || g.dmptemplate_id == template.id then
							include = true
							break
						end
					end
					if include then
						guidance_groups[gg.id] = gg.name
					end
				end
			end
		end
		respond_to do |format|
			format.json { render json: guidance_groups.to_json }
		end
	end

	private

	def orgs_of_type(org_type_name, published_templates = false)

		org_type = OrganisationType.find_by_name(org_type_name)
		all_such_orgs = org_type.organisations
		if published_templates then
			with_published = Array.new
			all_such_orgs.each do |o|
				if o.published_templates.count > 0 then
					with_published << o
				end
			end
			return with_published.sort_by {|o| [o.sort_name, o.name] }
		else
			return all_such_orgs.sort_by {|o| [o.sort_name, o.name] }
		end
	end

  #catch slugs and historic slugs also
  def find_project(params_id,relation = Project)

    id = nil

    begin

      id = Integer(params_id)

    rescue ArgumentError

      id = params_id

    end

    if id.is_a?(Integer)

      p = relation.where(:id => id).first

      if p.present?

        return p

      end

    elsif id.is_a?(String)

      p = relation.where(:slug => id).first

      if p.nil?

        fr = ActiveRecord::Base.connection_pool.with_connection { |con|
          con.exec_query("SELECT * FROM friendly_id_slugs WHERE slug = #{con.quote(id)} AND sluggable_type = 'Project' ORDER BY created_at DESC LIMIT 1")
        }.first

        if fr.present?

          p = relation.where(:id => fr["sluggable_id"]).first

        end

      else

        return p

      end

    end

    raise ActiveRecord::RecordNotFound

  end
end
