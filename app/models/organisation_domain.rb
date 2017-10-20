class OrganisationDomain < ActiveRecord::Base
  attr_accessible :name, :organisation_id

  validates :name, :length => { :minimum => 1 }, :uniqueness => true, :hostname => true
  validates :organisation, :presence => true
  belongs_to :organisation, :inverse_of => :organisation_domains
end
