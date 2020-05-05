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
    versions.sort { |a,b| a.number <=> b.number }.last
	end

	#Verify if this phase has any published versions
	def latest_published_version
    # b <=> a -> reverse sort
    versions
      .sort { |a,b| b.number <=> a.number }
      .select { |version| version.published }
      .first()
	end

	#verify if a phase has a published version or a version with one or more sections
	def has_sections

    #reverse sorted versions
    s_versions = versions.sort {|a,b| b.updated_at <=> a.updated_at }

    #published version (filter on previous list)
    p_versions = s_versions.select {|version| version.published }

		p_versions.size > 0 ?
      p_versions.first.sections.size > 0 :
      s_versions.first.sections.size > 0

	end

  def clone_to(t)

    raise ArgumentError.new( "should be instance of Dmptemplate" ) unless t.instance_of?(::Dmptemplate)

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
