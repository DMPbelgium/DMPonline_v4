class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :registerable, :invitable, :database_authenticatable, :recoverable, :confirmable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:shibboleth,:orcid]

  #associations between tables
  belongs_to :user_type
  belongs_to :user_status
  belongs_to :organisation
  has_many :answers, :dependent => :destroy
  has_many :project_groups, :dependent => :destroy

  has_many :projects, through: :project_groups do
    def filter(query)
      return self unless query.present?

      t = self.arel_table
      q = "%#{query}%"

      conditions = t[:title].matches(q)

      columns = %i(
        grant_number identifier description principal_investigator data_contact
      )

      columns.each {|col| conditions = conditions.or(t[col].matches(q)) }

      self.where(conditions)
    end
  end

  has_and_belongs_to_many :roles, :join_table => :users_roles
  has_many :plan_sections

  accepts_nested_attributes_for :roles
  attr_accessible :role_ids

  attr_accessible :password_confirmation, :encrypted_password, :remember_me, :id, :email, :firstname, :last_login,
   :login_count, :orcid_id, :password, :shibboleth_id, :user_status_id,
   :surname, :user_type_id, :organisation_id, :skip_invitation,
   :accept_terms, :role_ids, :dmponline3

  # FIXME: The duplication in the block is to set defaults. It might be better if
  #        they could be set in Settings::PlanList itself, if possible.
  has_settings :plan_list, class_name: 'Settings::PlanList' do |s|
    s.key :plan_list, defaults: { columns: Settings::PlanList::DEFAULT_COLUMNS }
  end

  validates :firstname,:length => { :minimum => 1 }
  validates :surname,:length => { :minimum => 1 }
  #can be empty, but, if not, should be unique
  validates :orcid_id,:length => { :minimum => 1 }, :uniqueness => true, :allow_blank => true
  #can be empty, but, if not, should be unique
  validates :shibboleth_id,:length => { :minimum => 1 }, :uniqueness => true, :allow_blank => true

	def name(use_email = true)
    fn = firstname.nil? ? "" : firstname
    sn = surname.nil? ? "" : surname
    fn.strip!
    sn.strip!

    if (fn == "" || sn == "") && use_email
      return email
    else
      name = "#{fn} #{sn}"
      return name.strip
    end
	end

	def is_admin?
		admin = roles.find_by_name("admin")
		return !admin.nil?
	end

	def is_org_admin?
		org_admin = roles.find_by_name("org_admin")
		return !org_admin.nil?
	end

  def org_type
    org_type = organisation.organisation_type.name
	  return org_type
  end

  @@after_auth_shibboleth_callbacks = []
  def self.after_auth_shibboleth(&callback)
    @@after_auth_shibboleth_callbacks << callback
  end
  def call_after_auth_shibboleth(auth,request)
    user = self
    @@after_auth_shibboleth_callbacks.each do |callback|
      callback.call(user,auth,request)
    end
  end

  def ensure_password
    unless self.password.present?
      self.generate_password
    end
  end
  def generate_password
    p = Devise.friendly_token[0,20]
    self.password = p
    self.password_confirmation = p
  end
  def writable_attributes
    whitelist = User.accessible_attributes - ["","id"]
    self.attributes.slice( *whitelist )
  end
  def is_guest?
    self.organisation_id == Organisation.guest_org.id
  end
end
