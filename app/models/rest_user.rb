class RestUser < ActiveRecord::Base

  attr_accessible :code, :token, :organisation_id

  before_validation do |record|

    if record.new_record?

      record.token = RestUser.generate_token()

    end

  end

  belongs_to :organisation
  validates :organisation, :presence => true

  validates :code,
    :length => { :minimum => 1 },
    :uniqueness => true,
    :format => { :with => /\A[a-zA-Z0-9]+\z/ }

  validates :token,
    :length => { :minimum => 10 }

  def self.generate_token

    SecureRandom.uuid()

  end

  def self.verify_and_load(organisation,code,token)

    self.where( :code => code, :token => token, :organisation_id => organisation.id ).first

  end

  def files

    internal_export_dir = self.organisation.internal_export_dir
    internal_export_url = self.organisation.internal_export_url

    unless File.exists?( internal_export_dir ) && File.directory?( internal_export_dir )

      return []

    end

    Dir.entries( dir )
      .select { |f|
        f != "." && f != ".."
      }
      .map { |f|

        full_f = File.join( dir, f )
        full_url = self.base_url + "/" + f
        type = File.symlink?(full_f) ? "symlink" : "file"
        self_url = type == "symlink" ? File.basename( File.readlink( full_f ) ) : f
        self_url = self.base_url + "/" + self_url

        {
          :id => full_url,
          :type => type,
          :links => { :self => self_url },
          :attributes => {
            :updated_at => File.mtime(full_f).utc.strftime("%FT%TZ")
          }
        }

      }

  end

end
