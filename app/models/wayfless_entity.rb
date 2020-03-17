require 'uri'

class WayflessEntity < ActiveRecord::Base
  attr_accessible :name, :url, :organisation_id

  validates :name, :length => { :minimum => 1 }, :uniqueness => true
  validates_format_of :url,:with => URI.regexp(['http', 'https']),:allow_blank => false
  validates :url, :uniqueness => true
  validates :organisation, :presence => true

  belongs_to :organisation, :inverse_of => :organisation_domains
end
