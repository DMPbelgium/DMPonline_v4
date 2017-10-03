User.before_validation do |user|
  if user.shibboleth_id.nil? || user.shibboleth_id.empty?
    user.shibboleth_id = user.email
  end
  if user.organisation.nil?
    user.organisation = Organisation.guest_org
  end
  true
end
User.after_auth_shibboleth do |user,auth,request|

 #always change organisation when authenticated against IDP
 #User model makes sure the user always has a default organisation! (see above)

 #match IDP against wayfless entity of organisation
 idp = request.env['Shib-Identity-Provider']

 org = Organisation.where(:wayfless_entity => idp).first

 unless org.nil?

   user.organisation_id = org.id

   if org.abbreviation == 'UGent'

     user.surname = auth['extra']['raw_info']['sn']
     user.firstname = auth['extra']['raw_info']['givenname']

   end

 end

  user.save if user.changed?

end

User.after_create do |u|
  UserMailer.report_new_user(u)
end
