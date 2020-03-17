ActiveAdmin.register WayflessEntity do

  filter :organisation, :collection => proc {
    Organisation.order("name asc")
  }
  filter :name
  filter :created_at
  filter :updated_at

  menu :priority => 17, :label => proc{I18n.t('admin.wayfless_entity')}, :parent => "Organisations management"

  show do
    attributes_table do
      row :id
      row :name
      row :url do |we|
        link_to(we.url,we.url).html_safe
      end
      row :organisation do |we|
        link_to(we.organisation.name, [:admin, we.organisation]).html_safe
      end
      row :created_at
      row :updated_at
    end
  end
end
