class Question < ActiveRecord::Base

  #associations between tables
  has_many :answers, :dependent => :destroy, :inverse_of => :question
  has_many :options, :dependent => :destroy, :inverse_of => :question
  has_many :suggested_answers, :dependent => :destroy, :inverse_of => :question
  has_many :guidances, :inverse_of => :question, :dependent => :destroy
  has_many :comments, :inverse_of => :question, :dependent => :destroy

  has_and_belongs_to_many :themes, join_table: "questions_themes"


  belongs_to :section, :inverse_of => :questions, :autosave => true
  belongs_to :question_format, :inverse_of => :questions, :autosave => true

  accepts_nested_attributes_for :answers, :reject_if => lambda {|a| a[:text].blank? },  :allow_destroy => true
  accepts_nested_attributes_for :section
  accepts_nested_attributes_for :question_format
  accepts_nested_attributes_for :options, :reject_if => lambda {|a| a[:text].blank? },  :allow_destroy => true
  accepts_nested_attributes_for :suggested_answers,  :allow_destroy => true
  accepts_nested_attributes_for :themes
  attr_accessible :theme_ids

  attr_accessible :default_value, :dependency_id, :dependency_text, :guidance,
  								:number, :parent_id, :suggested_answer, :text, :section_id,
  								:question_format_id,:options_attributes,
  								:suggested_answers_attributes
  #validation - start
  validates :section, :presence => true
  validates :question_format, :presence => true
  validates :text, :length => { :minimum => 1 }
  validates :number,numericality: { only_integer: true, :greater_than => 0 }
  #validation - end

	def to_s
        "#{text}"
    end

	#def question_type?
	#	type_label = {}
	#	if self.is_text_field?
	#	  type_label = 'Text field'
	#	elsif self.multiple_choice?
	#		type_label = 'Multiple choice'
	#	else
	#		type_label = 'Text area'
	#	end
	#	return type_label
	#end

	def question_themes?
		themes_label = {}
		i = 1
		themes_quest = self.themes

		themes_quest.each do |tt|
			themes_label = tt.title

			if themes_quest.count > i then
				themes_label +=	','
				i +=1
			end
		end

		return themes_label
	end

	#guidance for question in the org admin
	def guidance_for_question(question, org_admin)
    #pulls together guidance from various sources for question
    guidances = {}
    theme_ids = question.theme_ids

    GuidanceGroup.where("organisation_id = ?", org_admin.id).each do |group|
      group.guidances.each do |g|
        g.themes.where("id IN (?)", theme_ids).each do |gg|
          guidances["#{group.name} guidance on #{gg.title}"] = g
        end
      end
    end

	  #Guidance link to directly to a question
    question.guidances.each do |g_by_q|
      g_by_q.guidance_groups.each do |group|
        if group.organisation == org_admin
          guidances["#{group.name} guidance for this question"] = g_by_q
        end
      end
	  end

		return guidances
 	end


 	#get suggested answer belonging to the currents user for this question
 	def get_suggested_answer(org_id)
 		suggested_answer = suggested_answers.find_by_organisation_id(org_id)
 		return suggested_answer
 	end

  def clone_to(s)

    raise ArgumentError.new( "should be instance of Section" ) unless s.is_a?(::Section)

    raise ArgumentError.new( "Section instance should be persisted" ) unless s.persisted?

    question2 = self.dup

    s.questions << question2

    Rails.logger.info("[CLONE] COPIED Question[#{self.id}] to Question[#{question2.id}]")
    Rails.logger.info("[CLONE] ADDED Question[#{question2.id}] to Section[#{s.id}].questions")

    self.options.all.each do |option|

      option2 = option.dup
      question2.options << option2

      Rails.logger.info("[CLONE] COPIED Option[#{option.id}] to Option[#{option2.id}]")
      Rails.logger.info("[CLONE] ADDED Option[#{option2.id}] to Question[#{question2.id}].questions")

    end

    self.suggested_answers.all.each do |suggested_answer|

      suggested_answer2 = suggested_answer.dup
      question2.suggested_answers << suggested_answer2

      Rails.logger.info("[CLONE] COPIED SuggestedAnswer[#{suggested_answer.id}] to SuggestedAnswer[#{suggested_answer2.id}]")
      Rails.logger.info("[CLONE] ADDED SuggestedAnswer[#{suggested_answer2.id}] to Question[#{question2.id}].suggested_answers")

    end

    question2.theme_ids = self.theme_ids

    Rails.logger.info("[CLONE] ADDED #{self.theme_ids} to Question[#{question2.id}].theme_ids")

    self.guidances.all.each do |guidance|

      guidance2 = guidance.dup
      question2.guidances << guidance2

      Rails.logger.info("[CLONE] COPIED Guidance[#{guidance.id}] to Guidance[#{guidance2.id}]")
      Rails.logger.info("[CLONE] ADDED Guidance[#{guidance2.id}] to Question[#{question2.id}].guidances")

    end

    question2

  end

end
