class UserOrgRole < ActiveRecord::Base
  attr_accessible :organisation_id, :user_id, :user_role_type_id

  validates :user,:presence => true
  validates :organisation, :presence => true
  validates :user_role_type, :presence => true

  #associations between tables
  belongs_to :user
  belongs_to :organisation
  belongs_to :user_role_type

end
