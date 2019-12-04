Project.after_create do
  cu = User.current_user
  cu_attrs = cu.present? ?
    cu.attributes.slice("id","firstname","surname","email") : {}
  object = self.attributes
  object[:organisation] = self.organisation.attributes
  Log.create(
    :item_id        => self.id,
    :item_type      => "Project",
    :event          => "create",
    :whodunnit      => cu_attrs,
    :whodunnit_id   => cu.present? ? cu.id : nil,
    :object         => object
  )
end
Project.after_destroy do |project|
  cu = User.current_user
  cu_attrs = cu.present? ?
    cu.attributes.slice("id","firstname","surname","email") : {}
  object = project.attributes
  object[:organisation] = project.organisation.attributes
  Log.create(
    :item_id        => project.id,
    :item_type      => "Project",
    :event          => "destroy",
    :whodunnit      => cu_attrs,
    :whodunnit_id   => cu.present? ? cu.id : nil,
    :object         => object
  )
end
