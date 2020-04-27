# [+Project:+] DMPonline v4
# [+Description:+]
#
# [+Created:+] 03/09/2014
# [+Copyright:+] Digital Curation Centre

ActiveAdmin.register Version do

  #current version of active_admin does not support method "includes"
  controller do
    def scoped_collection
      super.includes(:phase)
    end
  end

  filter :phase, :collection => proc {
    Phase.order("title asc")
  }
  filter :title
  filter :description
  filter :published
  filter :number
  filter :created_at
  filter :updated_at

	menu :priority => 1, :label => proc{I18n.t('admin.version')}, :parent =>  "Templates management"

	index do   # :description, :number, :published, :title, :phase_id
    column I18n.t('admin.title'), :sortable => :title  do |version_used|
      if !version_used.title.nil? then
           link_to version_used.title, [:admin, version_used]
      end
    end
    column I18n.t('admin.version_numb'), :number
    column :published
    column I18n.t('admin.phase'), :sortable => :phase_id do |phase_title|
      if !phase_title.phase_id.nil? then
        link_to phase_title.phase.title, [:admin, phase_title.phase]
      else
        '-'
      end
    end
    default_actions
  end

  #show details of a version
  show do
		attributes_table do
		  row :title
	 		row	:number
	 		row :description do |descr|
	  		if !descr.description.nil? then
	  			descr.description.html_safe
	  		end
	  	end
	  	row I18n.t('admin.phase'), :sortable => :phase_id do |phase_title|
	  		if !phase_title.phase_id.nil? then
          link_to phase_title.phase.title, [:admin, phase_title.phase]
	   		end
     	end
     	row :published
     	row :created_at
     	row :updated_at
    end
    panel I18n.t('admin.sections') do
      table_for resource.sections.order("number asc") do
        column :number
        column :title do |section|
          link_to section.title, [:admin, section]
        end
        column I18n.t('admin.org_title'), :sortable => :organisation_id do |section|
          link_to section.organisation.name, [:admin,section.organisation]
        end
      end
    end
  end

  action_item only: %i(show) do
    link_to(
      "Add Section to Version",
      new_admin_section_path( "section[version_id]" => resource.id )
    )
  end

 	#form
 	form do |f|
  	f.inputs "Details" do
  		f.input :title
  		f.input :number
  		f.input :description
  		f.input :phase, :label => I18n.t('admin.phase_title'),
  			:as => :select,
  			:collection => Phase.find(:all, :order => 'title ASC').map{|ph|[ph.title, ph.id]}
  		f.input :published
  	end
  	f.actions
  end

end
