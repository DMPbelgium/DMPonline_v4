class Answer < ActiveRecord::Base

	#associations between tables
	belongs_to :question, :inverse_of => :answers, :autosave => true
	belongs_to :user, :inverse_of => :answers, :autosave => true
	belongs_to :plan, :inverse_of => :answers, :autosave => true
  accepts_nested_attributes_for :question
	accepts_nested_attributes_for :plan

  validates :question, :presence => true
  validates :user, :presence => true
  validates :plan, :presence => true

	has_and_belongs_to_many :options, join_table: "answers_options"

  attr_accessible :text, :plan_id, :question_id, :user_id, :option_ids

end
