class Project < ActiveRecord::Base

	attr_accessible :dmptemplate_id, :title, :organisation_id, :unit_id, :guidance_group_ids, :project_group_ids, :funder_id, :institution_id, :grant_number, :identifier, :description, :principal_investigator, :principal_investigator_identifier, :data_contact, :funder_name, :old_principal_investigator, :old_data_contact

	#associations between tables
	belongs_to :dmptemplate, :inverse_of => :projects, :autosave => true
	belongs_to :organisation, :autosave => true
	has_many :plans, :inverse_of => :project, :dependent => :destroy
	has_many :project_groups, :dependent => :destroy, :inverse_of => :project
	has_and_belongs_to_many :guidance_groups, join_table: "project_guidance"

	after_create :create_plans
  after_create :add_gdprs

  #validation - start
  validates :dmptemplate,:presence => true
  validates :title, :presence => true, :length => { :minimum => 1 }
  #validation - end

  #TODO: remove this? -> no, needed in assigment, but it shouldn't do anything
	def funder_id=(new_funder_id)
#		if new_funder_id != "" then
#			new_funder = Organisation.find(new_funder_id);
#			if new_funder.dmptemplates.count == 1 then
#				dmptemplate = new_funder.dmptemplates.first
#			end
#		end
	end

	def funder_id
		if dmptemplate.nil? then
			return nil
		end
		template_org = dmptemplate.organisation
		if template_org.organisation_type.name.downcase == I18n.t('helpers.org_type.funder').downcase
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
		if template_org.organisation_type.name.downcase == I18n.t('helpers.org_type.funder').downcase
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
#Too dangerous
#    unless new_funder_name.blank?
#      existing_org = Organisation.where( "name LIKE ? OR abbreviation LIKE ?", new_funder_name, new_funder_name).first
#      unless existing_org.nil?
#        self.funder_id=existing_org.id
#      end
#    end
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

  def principal_investigators
    project_groups.select {|pg| pg.project_pi }.map(&:user)
  end

  def principal_investigator
    principal_investigators.map { |u| u.render }.to_sentence.html_safe
  end

  def old_data_contact
    read_attribute("data_contact")
  end

  def old_data_contact=(dc)
    write_attribute("data_contact",dc)
  end

  def data_contacts
    project_groups.select {|pg| pg.project_data_contact }.map(&:user)
  end

  def data_contact
    data_contacts.map { |u| u.render }.to_sentence.html_safe
  end

  def gdprs
    project_groups.select {|pg| project_gdpr }.map(&:user)
  end

  def gdpr
    gdprs.map { |u| u.render }.to_sentence.html_safe
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
    project_groups.any? { |pg|
      pg.user_id == user_id && (
        pg.project_administrator ||
        pg.project_creator ||
        pg.project_pi
      )
    }
	end

	def editable_by(user_id)
    return false if user_id.nil?
    project_groups.any? { |pg|
      pg.user_id == user_id &&
      (
        pg.project_editor ||
        pg.project_administrator ||
        pg.project_creator ||
        pg.project_pi ||
        pg.project_data_contact ||
        pg.project_gdpr
      )
    }
	end

	def readable_by(user_id)
    return false if user_id.nil?
    project_groups.any? { |pg| pg.user_id == user_id }
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
    project_groups.any? {|pg| pg.user_id == user_id && pg.project_creator }
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
    project_groups.select {|pg| pg.project_creator }.first.try(:user)
	end

	def last_edited
		self.latest_update.to_date
	end

	def shared?
    shared_with > 0
	end

  def shared_with
    n = project_groups.map(&:user_id).uniq.size
    n > 0 ? n - 1 : 0
  end

	alias_method :shared, :shared?

	def template_owner
		self.dmptemplate.try(:organisation).try(:abbreviation)
	end

  def ld_uri

    Rails.application.routes.url_helpers.project_url(self, :host => ENV['DMP_HOST'], :protocol => ENV['DMP_PROTOCOL'])

  end

  def ld

    pr = {
      :id => self.id,
      :type => "Project",
      :url => self.ld_uri,
      :created_at => self.created_at.utc.strftime("%FT%TZ"),
      :updated_at => self.updated_at.utc.strftime("%FT%TZ"),
      :title => self.title,
      :description => self.description,
      :identifier => self.identifier,
      :grant_number => self.grant_number,
      :collaborators => self.project_groups.map { |pg|
        u = pg.user
        pg_r = {
          :type => "ProjectGroup",
          :user => nil,
          :access_level => pg.code_access_level,
          :created_at => pg.created_at.utc.strftime("%FT%TZ"),
          :updated_at => pg.updated_at.utc.strftime("%FT%TZ")
        }
        unless u.nil?

          pg_r[:user] = {
            :id => u.id,
            :type => "User",
            :created_at => u.created_at.utc.strftime("%FT%TZ"),
            :updated_at => u.updated_at.utc.strftime("%FT%TZ"),
            :email => u.email,
            :orcid => u.orcid_id
          }

        end
        pg_r
      },
      :organisation => nil,
      :plans => []
    }

    if self.organisation.present?

      pr[:organisation] = {
        :type => "Organisation",
        :id => self.organisation.id,
        :name => self.organisation.name
      }

    end

    dmptemplate = self.dmptemplate

    pr[:template] = dmptemplate.attributes
    pr[:template][:type] = "Template"

    funder = self.funder
    funder_name = self.read_attribute(:funder_name)

    if funder

      pr[:funder] = {
        :type => "Organisation",
        :id => funder.id,
        :name => funder.name
      }

    elsif funder_name.present?

      pr[:funder] = {
        :type => nil,
        :id => nil,
        :name => funder_name
      }

    else

      pr[:funder] = nil

    end

    self.plans.each do |plan|

      pr[:plans] << plan.ld

    end

    pr

  end

	private

	def create_plans
		dmptemplate.phases.each do |phase|
			latest_published_version = phase.latest_published_version
			unless latest_published_version.nil?
        self.plans << Plan.new(
          :version_id => latest_published_version.id
        )
			end
		end
	end

  def add_gdprs
    if self.dmptemplate.gdpr && !(self.organisation.nil?)
      self.organisation.gdprs.each do |user|
        ProjectGroup.create(
          :user_id => user.id,
          :project_id => self.id,
          :project_gdpr => true
        )
      end
    end
  end

end
