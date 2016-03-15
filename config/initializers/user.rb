User.before_validation do |user|
  if user.shibboleth_id.nil? || user.shibboleth_id.empty?
    user.shibboleth_id = user.email
  end
  true
end
User.after_auth_shibboleth do |user,auth,request|

  #only change organisation when none exists
  if user.organisation.nil?

    #match IDP against wayfless entity
    idp = request.env['Shib-Identity-Provider']

    orgs = Organisation.where(:wayfless_entity => idp)

    if orgs.size > 0

      org = orgs.first
      user.organisation_id=(org.id)
      user.save

      if org.abbreviation == 'UGent'

        user.surname = auth['extra']['raw_info']['sn']
        user.firstname = auth['extra']['raw_info']['givenname']

        #try to match against a more specific suborganisation
        if !org.nil? && org.is_parent?

          faculty = nil

          if !auth['extra']['raw_info']['department'].nil?

            faculty = auth['extra']['raw_info']['department'][0,2]

          elsif !auth['extra']['raw_info']['faculty'].nil?

            faculty = auth['extra']['raw_info']['faculty']

          end

          unless faculty.nil?

            fac_orgs = Organisation.where(:abbreviation => faculty, :parent_id => org.id)
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
