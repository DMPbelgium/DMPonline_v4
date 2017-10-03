class UserType < ActiveRecord::Base
  attr_accessible :description, :name

  #associations between tables
  has_many :users, :inverse_of => :user_type, :dependent => :destroy

  #validation - start
  validates :name, :length => { :minimum => 1 }, :uniqueness => true
  #validation - end
end
