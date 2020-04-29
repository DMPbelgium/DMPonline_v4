# [+Project:+] DMPonline v4
# [+Description:+] This model describes informmation about the phase of a plan, it's title, order of display and which template it belongs to.
#
# [+Created:+] 03/09/2014
# [+Copyright:+] Digital Curation Centre
class Phase < ActiveRecord::Base

	#associations between tables
	belongs_to :dmptemplate, :inverse_of => :phases, :autosave => true

	has_many :versions, :dependent => :destroy, :inverse_of => :phase
	has_many :sections, :through => :versions, :dependent => :destroy
  has_many :questions, :through => :sections, :dependent => :destroy

	#Link the child's data
	accepts_nested_attributes_for :versions, :allow_destroy => true
	accepts_nested_attributes_for :dmptemplate

	attr_accessible :description, :number, :title, :dmptemplate_id

  #validation - start
  validates :dmptemplate, :presence => true
  validates :title, :length => { :minimum => 1 }
  validates :number,numericality: { only_integer: true, :greater_than => 0 }
  #validation - end

	def to_s
		"#{title}"
	end

	def latest_version
		return versions.order("number DESC").last
	end

	#Verify if this phase has any published versions
	def latest_published_version
		versions.order("number DESC").each do |version|
			if version.published then
				return version
			end
		end
		return nil
	end

	#verify if a phase has a published version or a version with one or more sections
	def has_sections
		versions = self.versions.where('published = ?', true).order('updated_at DESC')
		if versions.any? then
			version = versions.first
			if !version.sections.empty? then
				has_section = true
			else
				has_section = false
			end
		else
			version = self.versions.order('updated_at DESC').first
			if !version.sections.empty? then
				has_section = true
			else
				has_section = false
			end
		end
		return has_section
	end

  def clone_to(t)

    raise ArgumentError.new( "should be instance of Dmptemplate" ) unless t.is_a?(::Dmptemplate)

    raise ArgumentError.new( "Dmptemplate instance should be persisted" ) unless t.persisted?

    p2 = self.dup
    t.phases << p2

    Rails.logger.info("[CLONE] COPIED Phase[#{self.id}] to Phase[#{p2.id}]")
    Rails.logger.info("[CLONE] ADDED Phase[#{p2.id}] to Dmptemplate[#{t.id}].phases")

    self.versions.each do |version|

      version.clone_to(p2)

    end

    p2

  end

end
