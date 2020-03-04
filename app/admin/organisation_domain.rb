ActiveAdmin.register OrganisationDomain do

  filter :organisation, :collection => proc {
    Organisation.order("name asc")
  }
  filter :name
  filter :created_at
  filter :updated_at

  menu :priority => 4, :label => proc{I18n.t('admin.org_domain')}, :parent => "Organisations management"

end
