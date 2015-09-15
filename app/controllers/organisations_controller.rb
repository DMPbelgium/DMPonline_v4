class OrganisationsController < ApplicationController
  # GET /organisations
  # GET /organisations.json
  def index
    authorize! :index, Organisation
    @organisations = Organisation.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @organisations }
    end
  end

  # GET /organisations/1
  # GET /organisations/1.json
  def admin_show
	  @organisation = Organisation.find(params[:id])
    authorize! :admin_show,@organisation

	  respond_to do |format|
	    format.html # show.html.erb
	    format.json { render json: @organisation }
	  end
  end

  # GET /organisations/new
  # GET /organisations/new.json
  def new
    authorize! :new, Organisation
    @organisation = Organisation.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @organisation }
    end
  end

  # GET /organisations/1/edit
  def admin_edit
	  @organisation = Organisation.find(params[:id])
    authorize! :admin_edit,@organisation

	  respond_to do |format|
	    format.html # edit.html.erb
	    format.json { render json: @organisation }
	  end
  end

  # POST /organisations
  # POST /organisations.json
  def create
    authorize! :create, Organisation
    @organisation = Organisation.new(params[:organisation])

    respond_to do |format|
      if @organisation.save
        format.html { redirect_to @organisation, notice: I18n.t("admin.org_created_message") }
        format.json { render json: @organisation, status: :created, location: @organisation }
      else
        format.html { render action: "new" }
        format.json { render json: @organisation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /organisations/1
  # PUT /organisations/1.json
  def admin_update
    @organisation = Organisation.find(params[:id])
    authorize! :admin_update,@organisation

	  respond_to do |format|
	    if @organisation.update_attributes(params[:organisation])
	      format.html { redirect_to admin_show_organisation_path(params[:id]), notice: I18n.t("admin.org_updated_message")  }
	      format.json { head :no_content }
	    else
	      format.html { render action: "edit" }
	      format.json { render json: @organisation.errors, status: :unprocessable_entity }
	    end
	  end
  end

  # DELETE /organisations/1
  # DELETE /organisations/1.json
  def destroy
    @organisation = Organisation.find(params[:id])
    authorize! :destroy, @organisation
    @organisation.destroy

    respond_to do |format|
      format.html { redirect_to organisations_url }
      format.json { head :no_content }
    end
  end

  #TODO: ?
  def parent
  	@organisation = Organisation.find(params[:id])
    authorize! :parent, @organisation
  	parent_org = @organisation.find_by {|o| o.parent_id }
  	return parent_org
  end

	def children
    authorize! :children, Organisation
		@organisation = Organisation.find(params[:id])
		children = {}
		@organisation.children.each do |child|
			children[child.id] = child.name
		end
		respond_to do |format|
			format.json { render json: children.to_json }
		end
	end

	def templates
    authorize! :templates, Organisation
		@organisation = Organisation.find(params[:id])
		templates = {}
		@organisation.dmptemplates.each do |template|
			if template.is_published? then
				templates[template.id] = template.title
			end
		end
		respond_to do |format|
			format.json { render json: templates.to_json }
		end
	end
end
