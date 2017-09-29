class OrganisationType < ActiveRecord::Base
  attr_accessible :description, :name

  has_many :organisations

  #validation - start
  validates :name, :length => { :minimum => 1 }
  #validation - end

  def self.guest_org_type
    org_type = OrganisationType.find_by_name("guests")

    if org_type.nil?

      org_type = OrganisationType.new(:name => "guests")

    end

    org_type
  end
end
