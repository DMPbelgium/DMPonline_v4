class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  before_filter :clear_sso_user
  after_filter :clear_invitation

  def shibboleth
    if user_signed_in? && current_user.shibboleth_id.present? && current_user.shibboleth_id.length > 0 then

      redirect_to edit_user_registration_path

    else
      auth = request.env['omniauth.auth'] || {}
      uid = auth.uid
      shibboleth_data = auth['extra']['raw_info']

      if !uid.nil? && !uid.blank? then
        uid = uid.downcase if ENV['SHIBBOLETH_UID_LOWERCASE'] == "true"

        s_user = User.where(shibboleth_id: uid).first
        @user = s_user

        # Stops Shibboleth ID being blocked if email incorrectly entered.
        if !s_user.nil? && s_user.try(:persisted?) then
          flash[:notice] = I18n.t('devise.omniauth_callbacks.success', :kind => 'Shibboleth')
          s_user.update_attribute('shibboleth_data',shibboleth_data.to_json)

          s_user.call_after_auth_shibboleth(auth,request)
          sign_in s_user
          redirect_to root_path
        else
          if user_signed_in? then
            s_user.updates_attributes(
              :shibboleth_id => uid,
              :shibboleth_data => shibboleth_data.to_json
            )
            current_user.update_attributes(
              :shibboleth_id => uid,
              :shibboleth_data => shibboleth_data.to_json
            )
            user_id = current_user.id
            sign_out current_user
            session.delete(:shibboleth_data)
            s_user = User.find(user_id)

            s_user.call_after_auth_shibboleth(auth,request)
            sign_in s_user
            redirect_to edit_user_registration_path
          else
            #create new user
            mail_field = ENV['SHIBBOLETH_MAIL_FIELD']
            mail_field = mail_field.nil? || mail_field.blank? ? :mail : ENV['SHIBBOLETH_MAIL_FIELD']
            s_user = User.new(
              :shibboleth_id => uid,
              :shibboleth_data => shibboleth_data.to_json,
              :email => auth['extra']['raw_info'][mail_field].downcase
            )
            #ensure password
            s_user.ensure_password

            #save
            s_user.save
            #login
            flash[:notice] = I18n.t('devise.omniauth_callbacks.success', :kind => 'Shibboleth')

            s_user.call_after_auth_shibboleth(auth,request)

            sign_in s_user
            redirect_to edit_user_registration_path
          end
        end
      else
        redirect_to root_path
      end
    end
  end
  def orcid

    auth = request.env['omniauth.auth'] || {}

    if user_signed_in?

      #link orcid
      current_user.orcid_id = auth.uid

      if current_user.valid?

        flash[:notice] = I18n.t("devise.omniauth_callbacks.orcid.linked")
        current_user.save

      else

        #happens when user changed email address:
        # 1. create user with email1
        # 2. set email in orcid
        # 3. login with orcid (orcid_id is set)
        # 4. reset email in orcid to email2
        # 5. create user with email2
        # 6. login with orcid: user with email2 cannot claim orcid, because it already belongs to user with email1
        flash[:alert] = current_user.errors.full_messages

      end

      redirect_to edit_user_registration_path

    else

=begin
#<OmniAuth::AuthHash credentials=#<OmniAuth::AuthHash expires=true expires_at=2103771161 refresh_token="bbbbfc77-85ae-4db9-b82c-4720c69c2b84" token="14465dd9-b9ac-4e37-b64b-3c4c98154820"> extra=#<OmniAuth::AuthHash raw_info=#<OmniAuth::AuthHash description=nil email="nicolas.franck@ugent.be" first_name="Nicolas" last_name="Franck" name=nil other_names=[nil] urls=#<OmniAuth::AuthHash>>> info=#<OmniAuth::AuthHash::InfoHash description=nil email="nicolas.franck@ugent.be" first_name="Nicolas" last_name="Franck" name=nil urls=#<OmniAuth::AuthHash>> provider="orcid" uid="0000-0002-5268-9669">
=end

=begin
  What this should do:

    1. Get Auth Hash (see above for an example)

    2. Extract uid (orcid_id), email, firstname and surname

    3. User found with same orcid_id:
      3.1. email NOT changed (users without email do not exist)
           so changing email in orcid does not do anything here.
           DO NOT change email
      3.2. set firstname if not present yet
      3.3. set surname if not present yet

    4. User not found based on orcid_id:
      4.1. User found with email adres same as the one in orcid:
        4.1.1. change orcid_id of that user record => what if that record has already an orcid_id, different from the one we get?
          => never change orcid
          user1 has confirmed email1
          user2 has set email in orcid to email1
          user2 logs in with orcid, so checking "user1.confirmed?" always returns true, but cannot be trusted

      4.2. No User found with email adres same as the one in orcid:
        4.2.1. create new user
        4.2.2. set orcid_id
        4.2.3. set email (when present)
=end

      uid = auth.uid
      email = auth['info']['email']
      @user = nil

      if uid.present?

        selectable_users = User.where( :orcid_id => uid ).all

        if selectable_users.size > 1

          session[:selectable_user_ids] = selectable_users.map(&:id)
          redirect_to edit_selectable_user_path
          return

        end

        @user = selectable_users.first

        #user found with orcid_id
        if @user

          #set firstname and surname when not present yet
          @user.firstname = auth['info']['first_name'] if @user.firstname.blank?
          @user.surname = auth['info']['last_name'] if @user.surname.blank?

        #no user found with orcid_id
        elsif email.present?

          user_with_email = User.where( :email => email ).first

          #user found with email
          if user_with_email

            #unable to trust this user
            redirect_to root_path, :alert => I18n.t("devise.omniauth_callbacks.orcid.link")
            return

          #no user found with email: NEW USER. We trust "email" because it has to be confirmed.
          else

            @user = User.new(
              :email => email,
              :orcid_id => uid,
              :firstname => auth['info']['first_name'],
              :surname => auth['info']['last_name']
            )

          end

        end

        if @user.new_record?

          @user.ensure_password

        end

        unless @user.valid?

          session[:sso_user] = @user.writable_attributes
          redirect_to edit_sso_user_path, alert: @user.errors.full_messages
          return

        else

          @user.save

          #login
          flash[:notice] = I18n.t('devise.omniauth_callbacks.success', :kind => 'ORCID')

          sign_in @user
          redirect_to edit_user_registration_path

        end

      else

        redirect_to root_path

      end

    end
  end

private
  def clear_sso_user
    session.delete(:sso_user)
  end
  def clear_invitation
    unless @user.nil?
      @user.accept_invitation! if @user.invitation_token.present?
    end
  end
end
