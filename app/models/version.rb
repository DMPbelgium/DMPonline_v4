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

  amoeba do
    include_association :sections
    include_association :questions
    set :published => 'false'
    prepend :title => "Copy of "
  end

  def custom_clone

    version2 = self.dup
    version2.published = false
    version2.title = "Copy of " + version2.title

    unless version2.save
      return nil
    end

    self.sections.all.each do |section|

      section2 = section.dup
      version2.sections << section2

      section.questions.all.each do |question|

        question2 = question.dup
        section2.questions << question2

        question.options.all.each do |option|

          option2 = option.dup
          question2.options << option2

        end

        question.suggested_answers.all.each do |suggested_answer|

          suggested_answer2 = suggested_answer.dup
          question2.suggested_answers << suggested_answer2

        end

        question2.theme_ids = question.theme_ids
        question2.guidance_ids = question.guidance_ids

      end

    end

    version2

  end

end
