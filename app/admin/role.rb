# [+Project:+] DMPonline v4
# [+Description:+]
#
# [+Created:+] 03/09/2014
# [+Copyright:+] Digital Curation Centre

ActiveAdmin.register Role do

  remove_filter :users

	menu :priority => 5, :label => proc{I18n.t('admin.role')}, :parent => "User management"

	index do
    column I18n.t('admin.title'), :sortable => :name do |role_name|
      link_to role_name.name, [:admin, role_name]
    end
    default_actions
  end

  show do
    attributes_table do
      row :name
      row :role_in_plans
      row :created_at
      row :updated_at
    end

    table_for( (Role.find(params[:id]).users)) do
      column (:email){|user| link_to user.email, [:admin, user]}
      column (:firstname){|user| user.firstname}
      column (:surname){|user| user.surname}
      column (:last_sign_in_at){|user| user.last_sign_in_at}
      column (I18n.t('admin.org_title')){|user|
        if !user.organisation.nil? then
          "-"
        end
      }
    end
	end

	form do |f|
    f.inputs "Details" do
      f.input :name
      f.input :role_in_plans
    end
    f.actions
  end

end
