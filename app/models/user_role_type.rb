#deprecated
#class UserRoleType < ActiveRecord::Base
#
#  #associations between tables
#  has_many :user_org_roles
#
#  attr_accessible :description, :name
#  validates :name, :presence => true, :length => { :minimum => 1 },:format => { :with => /\A[\w\-_]+\z/ },:uniqueness => true
#end
