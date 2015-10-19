User.after_auth_shibboleth do |user,auth,request|
  domain = request.host

  if user.organisation.nil?
    orgs = Organisation.where(:domain => domain)
    if orgs.size > 0
      user.organisation_id=(orgs.first.id)
    end
  end

  if domain =~ /ugent.be$/

    user.surname = auth['extra']['raw_info']['sn']
    user.firstname = auth['extra']['raw_info']['givenname']

    #try to match against a more specific suborganisation
    if !user.organisation.nil? && user.organisation.is_parent?

      faculty = nil

      if !auth['extra']['raw_info']['ugentdeptnumber1'].nil?

        faculty = auth['extra']['raw_info']['ugentdeptnumber1'][0,2]

      elsif !auth['extra']['raw_info']['ugentfaculty'].nil?

        faculty = auth['extra']['raw_info']['ugentfaculty']

      end

      unless faculty.nil?

        fac_orgs = Organisation.where(:abbreviation => faculty, :parent_id => user.organisation.id)
        if fac_orgs.size > 0

          user.organisation_id=(fac_orgs.first.id)

        end

      end
    end

  end

  user.save if user.changed?
end

User.after_create do |u|
  UserMailer.report_new_user(u)
end
