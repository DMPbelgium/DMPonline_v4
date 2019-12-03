ActiveAdmin.register RestUser do

  menu :priority => 1, :label => proc{ I18n.t("admin.rest_user")}, :parent => "User management"

	filter :code
	filter :organisation
	filter :created_at
	filter :updated_at

	index do

    column :code
    column :organisation
    column :created_at
    column :updated_at
  	default_actions

  end

  show do
  	attributes_table do
  		row :code
  		row :token
      row :organisation
  		row :created_at
  		row :updated_at
  	end
  end

  form do |f|
  	f.inputs "Details" do
      f.input :code
  		f.input :organisation_id ,:label => I18n.t('admin.org_title'),
  			:as => :select,
  			:collection => Organisation.find_all_by_parent_id(nil, :order => 'name ASC').map{|orgp|[orgp.name, orgp.id]}
    end
    f.actions
  end

  controller do
    def scoped_collection
      resource_class.includes(:organisation) # prevents N+1 queries to your database
    end
  end
end
