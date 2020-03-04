# [+Project:+] DMPonline v4
# [+Description:+]
#
# [+Created:+] 03/09/2014
# [+Copyright:+] Digital Curation Centre

ActiveAdmin.register OrganisationType do

  filter :organisations, :collection => proc {
    Organisation.order("name asc")
  }
  filter :name
  filter :description
  filter :created_at
  filter :updated_at

  menu :priority => 4, :label => proc{I18n.t('admin.org_type')}, :parent => "Organisations management"

	index do   #:organisation_id, :name
    column I18n.t('admin.title'), :sortable => :name do |ggn|
      link_to ggn.name, [:admin, ggn]
    end
    column I18n.t('admin.desc'), :description do |descr|
      if !descr.description.nil? then
        descr.description.html_safe
      end
    end
    default_actions
  end


  #show organisation type details
  show do
	  attributes_table do
		  row :name
		  row :description do |descr|
        if !descr.description.nil? then
          descr.description.html_safe
        end
      end
      row :created_at
      row :updated_at
	  end
	end

	#organisations sidebar
 	sidebar I18n.t('admin.orgs'), :only => :show, :if => proc { organisation_type.organisations.count >= 1} do
	  table_for organisation_type.organisations.order("name asc") do |org_list|
	    column I18n.t('admin.org_title'), :sortable => :name do |ggn|
        link_to ggn.name, [:admin, ggn]
      end
    end
  end

end
