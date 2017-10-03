class PlanSection < ActiveRecord::Base
  attr_accessible :plan_id, :release_time, :section_id, :user_id

  #associations between tables
  belongs_to :section, :inverse_of => :plan_sections, :autosave => true
  belongs_to :plan, :inverse_of => :plan_sections, :autosave => true
  belongs_to :user, :inverse_of => :plan_sections, :autosave => true

end
