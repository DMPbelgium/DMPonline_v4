class Project < ActiveRecord::Base

	extend FriendlyId

	attr_accessible :dmptemplate_id, :title, :organisation_id, :unit_id, :guidance_group_ids, :project_group_ids, :funder_id, :institution_id, :grant_number, :identifier, :description, :principal_investigator, :principal_investigator_identifier, :data_contact, :funder_name, :slug, :old_principal_investigator, :old_data_contact

	#associations between tables
	belongs_to :dmptemplate, :inverse_of => :projects, :autosave => true
	belongs_to :organisation, :autosave => true
	has_many :plans, :inverse_of => :project, :dependent => :destroy
	has_many :project_groups, :dependent => :destroy, :inverse_of => :project
	has_and_belongs_to_many :guidance_groups, join_table: "project_guidance"

	friendly_id :title, use: :slugged, :use => :history

	after_create :create_plans

  #validation - start
  validates :dmptemplate,:presence => true
  #validation - end

	def funder_id=(new_funder_id)
		if new_funder_id != "" then
			new_funder = Organisation.find(new_funder_id);
			if new_funder.dmptemplates.count == 1 then
				dmptemplate = new_funder.dmptemplates.first
			end
		end
	end

	def funder_id
		if dmptemplate.nil? then
			return nil
		end
		template_org = dmptemplate.organisation
		if template_org.organisation_type.name == I18n.t('helpers.org_type.funder').downcase
			return template_org.id
		else
			return nil
		end
	end

	def funder
		if dmptemplate.nil? then
			return nil
		end
		template_org = dmptemplate.organisation
		if template_org.organisation_type.name == I18n.t('helpers.org_type.funder').downcase
			return template_org
		else
			return nil
		end
	end

	def funder_name
		if self.funder.nil?
			return read_attribute(:funder_name)
		else
			return self.funder.name
		end
	end

	def funder_name=(new_funder_name)
		write_attribute(:funder_name, new_funder_name)
    unless new_funder_name.blank?
      existing_org = Organisation.where( "name LIKE ? OR abbreviation LIKE ?", new_funder_name, new_funder_name).first
      unless existing_org.nil?
        self.funder_id=existing_org.id
      end
    end
	end

	def institution_id=(new_institution_id)
		if organisation.nil? then
			self.organisation_id = new_institution_id
		end
	end

	def institution_id
		if organisation.nil?
			return nil
		else
			return organisation.root.id
		end
	end

	def unit_id=(new_unit_id)
		unless new_unit_id.nil? ||new_unit_id == ""
			self.organisation_id = new_unit_id
		end
	end

	def unit_id
		if organisation.nil? || organisation.parent_id.nil?
			return nil
		else
			return organisation_id
		end
	end

  def old_principal_investigator
    read_attribute("principal_investigator")
  end

  def old_principal_investigator=(pi)
    write_attribute("principal_investigator",pi)
  end

  def principal_investigator
    project_groups.where( :project_pi => true ).all.map(&:user).map { |u| u.render }.to_sentence.html_safe
  end

  def old_data_contact
    read_attribute("data_contact")
  end

  def old_data_contact=(dc)
    write_attribute("data_contact",dc)
  end

  def data_contact
    project_groups.where( :project_data_contact => true ).all.map(&:user).map { |u| u.render }.to_sentence.html_safe
  end

  def gdpr
    project_groups.where( :project_gdpr => true ).all.map(&:user).map { |u| u.render }.to_sentence.html_safe
  end

  def assign_data_contact(user_id)
    project_groups.build( :user_id => user_id, :project_data_contact => true )
  end

	def assign_creator(user_id)
    project_groups.build( :user_id => user_id, :project_creator => true )
	end

	def assign_editor(user_id)
		project_groups.build( :user_id => user_id, :project_editor => true )
	end

	def assign_reader(user_id)
		project_groups.build( :user_id => user_id )
	end

	def assign_administrator(user_id)
		project_groups.build( :user_id => user_id, :project_administrator => true )
	end

  def assign_pi(user_id)
    project_groups.build( :user_id => user_id, :project_pi => true )
  end

  def assign_gdpr(user_id)
    project_groups.build( :user_id => user_id, :project_gdpr => true )
  end

	def administerable_by(user_id)
    return false if user_id.nil?
		project_groups.where( "user_id = ? AND (project_administrator = ? OR project_creator = ? OR project_pi = ? OR project_gdpr = ?)", user_id, true, true, true, true ).count > 0
	end

	def editable_by(user_id)
    return false if user_id.nil?
    project_groups.where( "user_id = ? AND (project_editor = ? OR project_administrator = ? OR project_creator = ? OR project_pi = ? OR project_gdpr = ?)", user_id, true, true, true, true, true ).count > 0
	end

	def readable_by(user_id)
    return false if user_id.nil?
    project_groups.where( "user_id = ?", user_id ).count > 0
	end

	def self.projects_for_user(user_id)
		projects = Array.new
		groups = ProjectGroup.where("user_id = ?", user_id)
		unless groups.nil? then
			groups.each do |group|
				unless group.project.nil? then
					projects << group.project
				end
			end
		end
		return projects
	end

	def created_by(user_id)
		user = project_groups.find_by_user_id(user_id)
		if (! user.nil?) && user.project_creator then
			return true
		else
			return false
		end
	end

	def latest_update
		latest_update = updated_at
		plans.each do |plan|
			if plan.latest_update > latest_update then
				latest_update = plan.latest_update
			end
		end
		return latest_update
	end

	# Getters to match 'My plans' columns
	def name
		self.title
	end

	def owner
		self.project_groups.find_by_project_creator(true).try(:user)
	end

	def last_edited
		self.latest_update.to_date
	end

	def shared?
		self.project_groups.count > 1
	end

	alias_method :shared, :shared?

	def template_owner
		self.dmptemplate.try(:organisation).try(:abbreviation)
	end

	private

	def create_plans
		dmptemplate.phases.each do |phase|
			latest_published_version = phase.latest_published_version
			unless latest_published_version.nil?
				new_plan = Plan.new
				new_plan.version = latest_published_version
				plans << new_plan
			end
		end
	end
end
