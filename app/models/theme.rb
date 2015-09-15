class Theme < ActiveRecord::Base

  #associations between tables
  has_and_belongs_to_many :questions, join_table: "questions_themes"
  has_and_belongs_to_many :guidances, join_table: "themes_in_guidance"


  accepts_nested_attributes_for :guidances
  accepts_nested_attributes_for :questions

  attr_accessible :guidance_ids
  attr_accessible :question_ids
  attr_accessible :description, :title, :locale

  #validation - start
  validates :title, :length => { :minimum => 1 }, :uniqueness => true
  #validation - end

  def to_s
  	title
  end

end
