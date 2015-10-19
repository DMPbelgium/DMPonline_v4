User.after_auth_shibboleth do |user,auth,request|
  domain = request.host

  if user.organisation.nil?
    orgs = Organisation.where(:domain => domain)
    if orgs.size > 0
      user.organisation_id=(orgs.first.id)
      user.save
    end
  end

  if domain =~ /ugent.be$/
    user.surname = auth['extra']['raw_info']['sn']
    user.firstname = auth['extra']['raw_info']['givenname']
  end
end
