class SuggestedAnswer < ActiveRecord::Base

	belongs_to :organisation, :inverse_of => :suggested_answers, :autosave => true
	belongs_to :question, :inverse_of => :suggested_answers, :autosave => true

	accepts_nested_attributes_for :question

	attr_accessible :organisation_id, :question_id, :text, :is_example


	def to_s
    "#{text}"
  end

end
