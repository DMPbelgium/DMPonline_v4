class UserStatus < ActiveRecord::Base
  attr_accessible :description, :name

  #associations between tables
  has_many :users

  #validation
  validates :name,:length => { :minimum => 1}, :uniqueness => true
end
