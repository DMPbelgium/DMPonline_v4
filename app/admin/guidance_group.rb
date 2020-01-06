# [+Project:+] DMPonline v4
# [+Description:+]
#
# [+Created:+] 03/09/2014
# [+Copyright:+] Digital Curation Centre

ActiveAdmin.register GuidanceGroup do

  remove_filter :guidances
  remove_filter :projects

  menu :priority => 2, :label => proc{I18n.t('admin.guidance_group')}, :parent => "Guidance list"

	index do   #:organisation_id, :name, :published, :optional_subset
    column I18n.t('admin.name'), :sortable => :name do |ggn|
      link_to ggn.name, [:admin, ggn]
    end
    column I18n.t('admin.org_title'), :sortable => :organisation_id do |org_title|
      link_to org_title.organisation.name, [:admin, org_title.organisation]
    end
    column I18n.t('admin.template') do |t|
      (t.dmptemplates.map{|t_q| link_to t_q.title, [:admin, t_q]}).join(', ').html_safe
    end
    default_actions
  end

  #show details of guidance group
  show do
		attributes_table do
			row	:name
			row :organisation_id do |org_title|
        link_to org_title.organisation.name, [:admin, org_title.organisation]
      end
      row I18n.t('admin.template') do
        (guidance_group.dmptemplates.map{|t_q| link_to t_q.title, [:admin, t_q]}).join(', ').html_safe
      end
      row :created_at
      row :updated_at
		end
	end

	#guidance list
	sidebar I18n.t('admin.guidance'), :only => :show, :if => proc { guidance_group.guidances.count >= 1}  do
    table_for guidance_group.guidances.order("text asc") do |guis|
      column :text do |gtext|
        link_to gtext.text.html_safe, [:admin, gtext]
      end
#column theme_id from model Guidance since migration 20150416101954_remove_field_from_guidances.rb
#      column I18n.t('admin.theme'), :theme_id do |themelist|
#        themelist.theme
#      end
    end
  end

	#form
 	form do |f|
    f.inputs "Details" do
      f.input :name
      f.input :organisation_id, :label => I18n.t('admin.org_title'),
        :as => :select,
        :collection => Organisation.find(:all, :order => 'name ASC').map{|orgp|[orgp.name, orgp.id]}
      f.input :published
      f.input :optional_subset
    end

    f.inputs "Templates" do
      f.input :dmptemplate_ids,  :label => "Selected templates",
        :as => :select,
        :include_blank => "All Templates",
        :multiple => true,
        :collection => Dmptemplate.order('title').map{|the| [the.title, the.id]},
        :hint => 'Choose all templates that apply.'
    end
    f.actions
  end

end
