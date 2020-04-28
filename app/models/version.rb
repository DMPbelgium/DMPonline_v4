class Version < ActiveRecord::Base

  #associations between tables
  belongs_to :phase, :inverse_of => :versions, :autosave => true

  has_many :sections, :dependent => :destroy, :inverse_of => :version
  has_many :questions, :through => :sections, :dependent => :destroy
  has_many :plans, :dependent => :destroy

  #Link the data
	accepts_nested_attributes_for :phase
  accepts_nested_attributes_for :sections,  :allow_destroy => true

  attr_accessible :description, :number, :published, :title, :phase_id

  def to_s
  	"#{title}"
  end

  #validation - start
  validates :phase,:presence => true
  validates :title, :length => { :minimum => 1 }
  validates :number,numericality: { only_integer: true, :greater_than => 0 }
  #validation - end

  def global_sections
  	sections.find_all_by_organisation_id(phase.dmptemplate.organisation_id)
  end

  def clone_to(p)

    version2 = self.dup
    version2.published = false
    version2.title = "Copy of " + version2.title

    p.versions << version2

    self.global_sections.each do |section|

      section.clone_to(version2)

    end

    version2

  end

end
