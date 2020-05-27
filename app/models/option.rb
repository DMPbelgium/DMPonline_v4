class Option < ActiveRecord::Base

	#associations between tables
	belongs_to :question, :inverse_of => :options

  has_many :option_warnings, :dependent => :destroy, :inverse_of => :option
	has_and_belongs_to_many :answers, join_table: "answers_options"
  has_and_belongs_to_many :themes, join_table: "options_themes"

	attr_accessible :text, :question_id, :is_default, :number
  accepts_nested_attributes_for :themes
  attr_accessible :theme_ids

	#validation - start
  validates :question,:presence => true
  validates :text, :length => { :minimum => 1 }
  validates :number,numericality: { only_integer: true, :greater_than => 0 }
  #validation - end

	def to_s
		"#{text}"
	end

  def clone_to(q)

    raise ArgumentError.new( "should be instance of Question" ) unless q.instance_of?(::Question)

    raise ArgumentError.new( "Question instance should be persisted" ) unless q.persisted?

    option2 = self.dup
    q.options << option2

    Rails.logger.info("[CLONE] COPIED Option[#{self.id}] to Option[#{option2.id}]")
    Rails.logger.info("[CLONE] ADDED Option[#{option2.id}] to Question[#{q.id}].options")

    option2.theme_ids = self.theme_ids

    Rails.logger.info("[CLONE] ADDED #{self.theme_ids} to Option[#{option2.id}].theme_ids")

  end
end
