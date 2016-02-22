# [+Project:+] DMPonline v4
# [+Description:+]
#
# [+Created:+] 03/09/2014
# [+Copyright:+] Digital Curation Centre

ActiveAdmin.register UserOrgRole do
	menu :priority => 5, :label => proc{I18n.t('admin.user_org_role')}, :parent => "User management"

	index do   # :user_id, :organisation_id, :user_role_type_id
    column I18n.t('admin.user'), :sortable => :user_id do |user_n|
      if !user_n.user.nil? then
        link_to user_n.user.firstname, [:admin, user_n.user]
      end
    end
    column I18n.t('admin.org'), :sortable => :organisation_id do |org|
      if !org.organisation.nil? then
        link_to org.organisation.name, [:admin, org.organisation]
      end
    end
    column I18n.t('admin.user_role_type'), :sortable => :user_role_type_id do |role|
      if !role.user_role_type.nil? then
        link_to role.user_role_type.name, [:admin, role.user_role_type]
      end
    end
    default_actions
  end

  show do
		attributes_table do
		  row I18n.t('admin.user'), :user_id do |user_n|
        unless user_n.try(:user).nil?
          link_to user_n.user.firstname, [:admin, user_n.user]
        else
          "-"
        end
      end
      row I18n.t('admin.org'), :organisation_id do |org|
        unless org.try(:organisation).nil?
          link_to org.organisation.name, [:admin, org.organisation]
        else
          "-"
        end
      end
      row I18n.t('admin.user_role_type'), :user_role_type_id do |role|
        unless role.try(:user_role_type).nil?
          link_to role.user_role_type.name, [:admin, role.user_role_type]
        else
          "-"
        end
      end
      row :created_at
      row :updated_at
    end
  end
end
