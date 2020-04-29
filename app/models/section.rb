class Section < ActiveRecord::Base

  #associations between tables
  belongs_to :version, :inverse_of => :sections, :autosave => true
  belongs_to :organisation, :inverse_of => :sections, :autosave => true
  has_many :questions, :dependent => :destroy, :inverse_of => :section
  has_many :plan_sections, :dependent => :destroy, :inverse_of => :section

  #Link the data
  accepts_nested_attributes_for :questions, :reject_if => lambda {|a| a[:text].blank? },  :allow_destroy => true
  accepts_nested_attributes_for :version

  attr_accessible :organisation_id, :description, :number, :title, :version_id , :published, :questions_attributes

  #validation - start
  validates :version,:presence => true
  validates :organisation,:presence => true
  validates :title, :length => { :minimum => 1 }
  validates :number,numericality: { only_integer: true, :greater_than => 0 }
  #validation - end

  def to_s
    "#{title}"
  end

  def clone_to(v)

    raise ArgumentError.new( "should be instance of Version" ) unless v.is_a?(::Version)

    raise ArgumentError.new( "Version instance should be persisted" ) unless v.persisted?

    section2 = self.dup

    v.sections << section2

    Rails.logger.info("[CLONE] COPIED Section[#{self.id}] to Section[#{section2.id}]")
    Rails.logger.info("[CLONE] ADDED Section[#{section2.id}] to Version[#{v.id}].sections")

    self.questions.all.each do |question|

      question.clone_to(section2)

    end

    section2

  end

end
