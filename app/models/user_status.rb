class UserStatus < ActiveRecord::Base
  attr_accessible :description, :name

  #associations between tables
  has_many :users, :dependent => :destroy, :inverse_of => :user_status

  #validation - start
  validates :name,:length => { :minimum => 1}, :uniqueness => true
  #validation - end
end
