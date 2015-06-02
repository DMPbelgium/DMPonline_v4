class OrganisationType < ActiveRecord::Base
  attr_accessible :description, :name

  has_many :organisations

  #validation
  validates :name, :length => { :minimum => 1 }

end
