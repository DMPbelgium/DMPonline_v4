# [+Project:+] DMPonline v4
# [+Description:+]
#
# [+Created:+] 03/09/2014
# [+Copyright:+] Digital Curation Centre

ActiveAdmin.register SuggestedAnswer do
  filter :organisation, :collection => proc {
    Organisation.order("name asc")
  }
  filter :text
  filter :created_at
  filter :updated_at
  filter :is_example

	menu :priority => 1, :label => proc{I18n.t('admin.sug_answer')}, :parent => "Templates management"

  #form
 	form do |f|
  	f.inputs "Details" do
      f.input :question_id, :label => I18n.t('admin.question'),
        :as => :select,
        :collection => Question.find(:all, :order => 'text ASC').map{|ques|[ques.text, ques.id]}
      f.input :organisation_id, :label => I18n.t('admin.org_title'),
        :as => :select,
        :collection => Organisation.find(:all, :order => 'name ASC').map{|orgp|[orgp.name, orgp.id]}
      f.input :text
      f.input :is_example
    end
  	f.actions
  end

end
