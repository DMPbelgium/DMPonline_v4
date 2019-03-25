class ProjectGroup < ActiveRecord::Base

  @@t_access_levels = [
    "helpers.project.share.owner",
    "helpers.project.share.co_owner",
    "helpers.project.share.pi",
    "helpers.project.share.edit",
    "helpers.project.share.data_contact",
    "helpers.project.share.gdpr",
    "helpers.project.share.read_only",
  ]


  #associations between tables
  belongs_to :project, :inverse_of => :project_groups, :autosave => true
  belongs_to :user, :inverse_of => :project_groups, :autosave => true
  validates :project, :presence => true
  validates :user, :presence => true

  attr_accessible :project_creator, :project_editor, :project_administrator, :project_id, :user_id, :email, :access_level, :project_pi, :project_gdpr, :project_data_contact

  def email
    self.user.nil? ? nil : self.user.email
  end

  def email=(new_email)
    self.user = User.find_by_email(email)
  end

  def access_level
    if self.project_creator
      return 0
    elsif self.project_administrator
      return 1
    elsif self.project_pi
      return 2
  	elsif self.project_editor
  		return 3
    elsif self.project_data_contact
      return 4
    elsif self.project_gdpr
      return 5
  	else
  		return 6
  	end
  end

  def access_level=(new_access_level)
  	new_access_level = new_access_level.to_i
    self.project_administrator = new_access_level == 1
    self.project_pi = new_access_level == 2
    self.project_editor = new_access_level == 3
    self.project_data_contact = new_access_level == 4
    self.project_gdpr = new_access_level == 5
  end

  def self.assignable_access_levels

    (1..6).to_a

  end

  def t
    if project_creator
      return I18n.t("helpers.project.share.owner")
    elsif project_administrator
      return I18n.t("helpers.project.share.co_owner")
    elsif project_pi
      return I18n.t("helpers.project.share.pi")
    elsif project_editor
      return I18n.t("helpers.project.share.edit")
    elsif project_data_contact
      return I18n.t("helpers.project.share.data_contact")
    elsif project_gdpr
      return I18n.t("helpers.project.share.gdpr")
    end
    I18n.t("helpers.project.share.read_only")
  end

  def self.t_access_level(access_level)

    I18n.t( @@t_access_levels[ access_level ] )

  end

  def t_access_level

    self.class.t_access_level( self.access_level )

  end

  def self.selectable_access_levels

    self.assignable_access_levels.map { |a| [ self.t_access_level(a), a ] }

  end


end
