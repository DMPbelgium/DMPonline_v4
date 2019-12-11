Project.after_create do |project|
  cu = User.current_user
  cu_attrs = cu.present? ?
    cu.attributes.slice("id","firstname","surname","email") : {}
  object = project.attributes
  if project.organisation.present?
    object[:organisation] = project.organisation.attributes
  end
  Log.create(
    :item_id        => project.id,
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
  if project.organisation.present?
    object[:organisation] = project.organisation.attributes
  end
  Log.create(
    :item_id        => project.id,
    :item_type      => "Project",
    :event          => "destroy",
    :whodunnit      => cu_attrs,
    :whodunnit_id   => cu.present? ? cu.id : nil,
    :object         => object
  )
end
