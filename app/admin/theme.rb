# [+Project:+] DMPonline v4
# [+Description:+]
#
# [+Created:+] 03/09/2014
# [+Copyright:+] Digital Curation Centre

ActiveAdmin.register Theme do

	menu :priority => 12, :label => "Themes"

	index do   # :description, :title, :locale
  	column :title , :sortable => :title do |theme|
      link_to theme.title, [:admin, theme]
    end
		column :description do |descr|
  		if !descr.description.nil? then
  			descr.description.html_safe
  		end
  	end
  	default_actions
  end

  #show details of a theme
  show do
  	attributes_table do
      row :title
      row :description
      row :created_at
      row :updated_at
    end

    table_for( (Theme.find(params[:id]).questions).order('number')) do
      column (:number){|question| question.number}
      column (I18n.t("admin.question")){|question| link_to question.text, [:admin, question]}
      column (I18n.t("admin.template")){|question|
        if !question.section.nil? then
          if !question.section.version.nil? then
            if !question.section.version.phase.nil? then
              if !question.section.version.phase.dmptemplate.nil? then
                link_to question.section.version.phase.dmptemplate.title, [:admin, question.section.version.phase.dmptemplate]
              else
                'No template'
              end
            else
              'No phase'
            end
          else
            'No version'
          end
        else
            'No section'
        end
      }
    end
  end


  #form
  form do |f|
  	f.inputs "Details" do
  		f.input :title
  		f.input :description
		end
		 f.actions
	end

end
