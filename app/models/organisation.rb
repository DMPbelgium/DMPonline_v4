class Organisation < ActiveRecord::Base

	#associations between tables
	belongs_to :organisation_type, :inverse_of => :organisations, :autosave => true
	has_many :guidance_groups, :inverse_of => :organisation, :dependent => :destroy
  has_many :dmptemplates, :inverse_of => :organisation, :dependent => :destroy
	has_many :sections, :inverse_of => :organisation, :dependent => :destroy
	has_many :users, :dependent => :destroy, :inverse_of => :organisation
	has_many :option_warnings, :inverse_of => :organisation, :dependent => :destroy
	has_many :suggested_answers, :inverse_of => :organisation, :dependent => :destroy
  has_many :organisation_domains, :inverse_of => :organisation, :dependent => :destroy

  belongs_to :parent, :class_name => 'Organisation', :autosave => true
	has_many :children, :class_name => 'Organisation', :foreign_key => 'parent_id'

	accepts_nested_attributes_for :organisation_type
	accepts_nested_attributes_for :dmptemplates

	attr_accessible :abbreviation, :banner_file_id, :description, :logo_file_id, :name, :stylesheet_file_id, :target_url, :organisation_type_id, :wayfless_entity, :parent_id, :sort_name, :gdpr
  #validation - start
  validates :organisation_type,:presence => true
  validates :name, :length => { :minimum => 1 }
  validates :abbreviation,
    :length => { :minimum => 1 },
    :uniqueness => true,
    :format => {
      :with => /\A[a-zA-Z0-9\-]+\z/
    }

  def is_parent?
    self.parent_id.nil?
  end
  #with_options if: :is_parent? do |parent|
  #  parent.validates :wayfless_entity, :uniqueness => true, :allow_nil => true, :allow_blank => true
  #end
  with_options unless: :is_parent? do |child|
    child.validates_each :wayfless_entity do |record,attr,value|
      record.errors.add(:wayfless_entity, :absence) if value.present?
    end
  end
  #validation - end

	def to_s
		name
	end

	def short_name
		if abbreviation.nil? then
			return name
		else
			return abbreviation
		end
	end

	#retrieves info off a child org
	def self.orgs_with_parent_of_type(org_type)
		parents = OrganisationType.find_by_name(org_type).organisations
		children = Array.new
		parents.each do |parent|
		  	children += parent.children
		end
		return children
	end


	def self.other_organisations
		org_types = [I18n.t('helpers.org_type.organisation')]
		organisations_list = []
		org_types.each do |ot|
			new_org_obejct = OrganisationType.find_by_name(ot)

			org_with_guidance = GuidanceGroup.joins(new_org_obejct.organisations)

			organisations_list = organisations_list + org_with_guidance
		end
		return organisations_list
	end

	def all_sections(version_id)
		if parent.nil?
			secs = sections.where("version_id = ?", version_id)
			if secs.nil? then
				secs = Array.new
			end
			return secs
		else
			return sections.find_all_by_version_id(version_id) + parent.all_sections(version_id)
		end
	end

	def all_guidance_groups
		ggs = guidance_groups
		children.each do |c|
			ggs = ggs + c.all_guidance_groups
		end
		return ggs
	end

	def root
		if parent.nil?
			return self
		else
			return parent.root
		end
	end

	def warning(option_id)
		warning = option_warnings.find_by_option_id(option_id)
		if warning.nil? && !parent.nil? then
			return parent.warning(option_id)
		else
			return warning
		end
	end

	def published_templates
		return dmptemplates.find_all_by_published(1)
	end

  def gdpr_templates
    dmptemplates.where(:gdpr => true)
  end

  def self.guest_org
    org = Organisation.find_by_name("guests")

    if org.nil?
      org = Organisation.new(
        :name => "guests",
        :abbreviation => "guests",
        :parent_id => nil,
        :sort_name => "guests"
      )
    end
    if org.organisation_type.nil?
      org.organisation_type = OrganisationType.guest_org_type
    end

    org
  end

  def gdprs

    User.all(
      :joins => :roles,
      :conditions => {
        :roles => { :name => "org_gdpr" },
        :organisation_id => self.id }
    )

  end

  def internal_export_dir

    File.join(
      (ENV["INTERNAL_EXPORTS"].present? ?
        ENV["INTERNAL_EXPORTS"] : "/opt/dmponline_internal"),
      self.abbreviation
    )

  end

  def internal_export_url

    u = Rails.application
      .routes
      .url_helpers
      .root_url(:host => ENV['DMP_HOST'], :protocol => ENV['DMP_PROTOCOL'])
    u.chomp!("/")
    u += "/internal/exports/v01/organisations/" + self.abbreviation
    u

  end

  def internal_export_files

    base_dir = self.internal_export_dir
    base_url = self.internal_export_url

    files = Dir
      .glob( File.join( base_dir, "*", "*", "*.json" ) )
      .map { |f|

        rel_name = f.gsub( base_dir + "/" , "" )
        full_url = base_url + "/" + rel_name
        self_url = base_url + "/" + rel_name

        {
          :id => full_url,
          :type => "file",
          :links => { :self => self_url },
          :attributes => {
            :updated_at => File.mtime(f).utc.strftime("%FT%TZ")
          }
        }

      }

    files += Dir
      .glob( File.join(base_dir,"*.json") )
      .select { |f| File.symlink?(f) }
      .map { |f|

        rel_name = f.gsub( base_dir + "/" , "" )
        full_url = base_url + "/" + rel_name
        self_rel_name = File.readlink(f).gsub( base_dir + "/" , "" )
        self_url = base_url + "/" + self_rel_name

        {
          :id => full_url,
          :type => "link",
          :links => { :self => self_url },
          :attributes => {
            :updated_at => File.mtime(f).utc.strftime("%FT%TZ")
          }
        }

      }

  end

end
