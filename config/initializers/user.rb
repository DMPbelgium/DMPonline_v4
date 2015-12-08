User.after_auth_shibboleth do |user,auth,request|

  #only change organisation when none exists
  if user.organisation.nil?

    #match IDP against wayfless entity

    pid = auth['extra']['raw_info']['persistent-id']
    idp = nil
    #persistent-id: <idp>!<sp>!<session-id>
    if !(pid.nil?) && !(pid.empty?)
      idp = pid.split('!').first
    end

    orgs = Organisation.where(:wayfless_entity => idp)

    if orgs.size > 0

      org = orgs.first
      user.organisation_id=(org.id)

      if org.abbreviation == 'UGent'

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

    end
  end

  user.save if user.changed?
end

User.after_create do |u|
  UserMailer.report_new_user(u)
end
