class QuestionFormat < ActiveRecord::Base
  attr_accessible :title, :description

  #associations between tables
  has_many :questions, :dependent => :destroy, :inverse_of => :question_format

  def to_s
    "#{title}"
  end
end
