class ProjectGroup < ActiveRecord::Base

  #associations between tables
  belongs_to :project, :inverse_of => :project_groups, :autosave => true
  belongs_to :user, :inverse_of => :project_groups, :autosave => true
  validates :project, :presence => true
  validates :user, :presence => true

  attr_accessible :project_creator, :project_editor, :project_administrator, :project_id, :user_id, :email, :access_level, :project_pi, :project_gdpr

  def email
    self.user.nil? ? nil : self.user.email
  end

  def email=(new_email)
    self.user = User.find_by_email(email)
  end

  def access_level
    if self.project_pi
      return 5
    elsif self.project_gdpr
      return 4
  	elsif self.project_administrator
  		return 3
  	elsif self.project_editor
  		return 2
  	else
  		return 1
  	end
  end

  def access_level=(new_access_level)
  	new_access_level = new_access_level.to_i
    self.project_administrator = new_access_level == 3
    self.project_editor = new_access_level == 2
    self.project_pi = new_access_level == 5
    self.project_gdpr = new_access_level == 4
  end

end
