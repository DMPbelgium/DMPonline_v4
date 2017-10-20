ActiveAdmin.register OrganisationDomain do

  menu :priority => 4, :label => proc{I18n.t('admin.org_domain')}, :parent => "Organisations management"

end
