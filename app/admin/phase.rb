# [+Project:+] DMPonline v4
# [+Description:+]
#
# [+Created:+] 03/09/2014
# [+Copyright:+] Digital Curation Centre

ActiveAdmin.register Phase do

  #current version of active_admin does not support method "includes"
  controller do
    def scoped_collection
      super.includes( :dmptemplate )
    end
  end

  filter :dmptemplate, :collection => proc {
    Dmptemplate.order("title asc")
  }
#  filter :versions, :collection => proc {
#    Version.order("title asc")
#  }
#  filter :sections, :collection => proc {
#    Section.order("title asc")
#  }
  filter :title
  filter :description
  filter :number
  filter :created_at
  filter :updated_at

	menu :priority => 1, :label => proc{I18n.t('admin.phase')}, :parent => "Templates management"

	# :description, :number, :title, :dmptemplate_id
	index do
    column :title, :sortable => :title do |ph|
      if !ph.title.nil? then
        link_to ph.title, [:admin, ph]
      end
    end
    column :number
    column I18n.t('admin.template'), :sortable => :dmptemplate_id do |temp_title|
      if !temp_title.nil? then
        link_to temp_title.dmptemplate.title, [:admin, temp_title.dmptemplate]
      end
    end

    default_actions
  end

  #show details of a phase
  show do
    attributes_table do
      row :title
      row	:number
      row :description do |descr|
        if !descr.description.nil? then
          descr.description.html_safe
        end
      end
      row I18n.t('admin.template'), :sortable => :dmptemplate_id do |temp_title|
        link_to temp_title.dmptemplate.title, [:admin, temp_title.dmptemplate]
      end
      row :created_at
      row :updated_at
    end
    panel I18n.t('admin.versions') do
      table_for phase.versions.order("number asc") do
        column :number
        column :title do |row|
          link_to row.title, [:admin, row]
        end
        column :published
      end
    end
	end

  action_item only: %i(show) do
    link_to(
      "Add Version to Phase",
      new_admin_version_path( "version[phase_id]" => resource.id )
    )
  end

 	#form
 	form do |f|
    f.inputs "Details" do
      f.input :title
      f.input :number
      f.input :description
      f.input :dmptemplate_id, :label => I18n.t('admin.template'),
        :as => :select,
        :collection => Dmptemplate.find(:all, :order => 'title ASC').map{|temp|[temp.title, temp.id]}

    end
    f.actions
  end

end
