User.before_validation do |user|

  #downcase email of new user
  if user.new_record?

    user.email.downcase! if user.email.present?

  #do not allow email changes
  elsif user.email_changed?

    user.email = user.email_was

  end

  #default shibboleth_id == email
  if user.shibboleth_id.blank?

    user.shibboleth_id = user.email

  end

  #only (re)set organisation during creation
  if user.new_record? || user.organisation.nil?

    if user.email.present?

      parts_email = user.email.split("@")
      if parts_email.size == 2
        #organisation now set at creation time, and not on authentication time ( where wayfless_entity was equal to request.env['Shib-Identity-Provider'] )
        org_domain = OrganisationDomain.where( :name => parts_email[1] ).first
        user.organisation = org_domain.nil? ? Organisation.guest_org : org_domain.organisation
      end

    else

      user.organisation = Organisation.guest_org

    end

  end

  user.ensure_password

  true
end
User.after_auth_shibboleth do |user,auth,request|

  if auth['extra'].is_a?(Hash) && auth['extra']['raw_info'].is_a?(Hash) && user.nemo?

    #user ALWAYS has default firstname and surname, so checking on "blank?" does not help.
    user.surname = auth['extra']['raw_info']['sn']
    user.firstname = auth['extra']['raw_info']['givenname']

  end

  user.save if user.changed?

end

User.after_create do |u|
  UserMailer.report_new_user(u)
end
