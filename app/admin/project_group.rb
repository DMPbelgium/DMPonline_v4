# [+Project:+] DMPonline v4
# [+Description:+]
#
# [+Created:+] 03/09/2014
# [+Copyright:+] Digital Curation Centre

ActiveAdmin.register ProjectGroup do

  filter :user, :collection => proc {
    User.order("firstname asc, surname asc, email asc")
  }
  filter :project_creator
  filter :project_administrator
  filter :project_editor
  filter :project_pi
  filter :project_gdpr
  filter :project_data_contact
  filter :created_at
  filter :updated_at

end
