class SuggestedAnswer < ActiveRecord::Base

	belongs_to :organisation, :inverse_of => :suggested_answers
	belongs_to :question, :inverse_of => :suggested_answers

  #TODO: this, together with "autosave=true" for the relations "belongs_to",
  #triggers "SystemStackError: stack level too deep"
  #probably due to callback chain child->parent->child->parent ..
  #Possible side effects of this "fix"?
	#accepts_nested_attributes_for :question

	attr_accessible :organisation_id, :question_id, :text, :is_example


	def to_s
    "#{text}"
  end

end
