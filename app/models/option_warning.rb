class OptionWarning < ActiveRecord::Base
	#associations between tables
	belongs_to :option, :inverse_of => :option_warnings, :autosave => true
	belongs_to :organisation, :inverse_of => :option_warnings, :autosave => true

  attr_accessible :text, :option_id, :organisation_id

	def to_s
		"#{text}"
	end
end
