User.before_validation do |user|

  #downcase email of new user
  if user.new_record?

    user.email.downcase!

  #do not allow email changes
  elsif user.email_changed?

    user.email = user.email_was

  end

  #default shibboleth_id == email
  if user.shibboleth_id.blank?

    user.shibboleth_id = user.email

  end

  #only (re)set organisation during creation
  if user.new_record?

    if user.email.present?

      parts_email = user.email.split("@")
      if parts_email.size == 2
        #organisation now set at creation time, and not on authentication time ( where wayfless_entity was equal to request.env['Shib-Identity-Provider'] )
        org = Organisation.where( :domain => parts_email[1] ).first
        user.organisation = org.nil? ? Organisation.guest_org : org
      end

    else

      user.organisation = Organisation.guest_org

    end

  end

  true
end
User.after_auth_shibboleth do |user,auth,request|

  #User model makes sure the user always has a default organisation! (see above)

  #match IDP against wayfless entity of organisation
  idp = request.env['Shib-Identity-Provider']

  org = Organisation.where(:wayfless_entity => idp).first

  unless org.nil?

    if org.abbreviation.present? && org.abbreviation == 'UGent'

      if auth['extra'].is_a?(Hash) && auth['extra']['raw_info'].is_a?(Hash)

        user.surname = auth['extra']['raw_info']['sn'] if user.surname.blank?
        user.firstname = auth['extra']['raw_info']['givenname'] if user.firstname.blank?

      end

    end

  end

  user.save if user.changed?

end

User.after_create do |u|
  UserMailer.report_new_user(u)
end
