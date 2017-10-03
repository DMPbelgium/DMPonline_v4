class Comment < ActiveRecord::Base

  #associations between tables
  belongs_to :question, :inverse_of => :comments, :autosave => true

  #fields
  attr_accessible :question_id, :text, :user_id, :archived, :plan_id, :archived_by

  def to_s
      "#{text}"
  end

end
