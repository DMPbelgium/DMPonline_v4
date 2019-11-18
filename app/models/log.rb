class Log < ActiveRecord::Base
  serialize :object, JSON
  serialize :whodunnit, JSON
  attr_accessible :item_id,:item_type,:event,:whodunnit,:whodunnit_id,:object
end
