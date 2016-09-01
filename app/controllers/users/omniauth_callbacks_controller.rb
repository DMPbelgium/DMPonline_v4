class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  #TODO: what if someone was invited?

  before_filter :clear_sso_user
  after_filter :clear_invitation

  def shibboleth
    if user_signed_in? && current_user.shibboleth_id.present? && current_user.shibboleth_id.length > 0 then
      flash[:warning] = I18n.t('devise.failure.already_authenticated')
      redirect_to root_path
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

      flash[:warning] = I18n.t('devise.failure.already_authenticated')
      redirect_to root_path
      return

    else

=begin
#<OmniAuth::AuthHash credentials=#<OmniAuth::AuthHash expires=true expires_at=2103771161 refresh_token="bbbbfc77-85ae-4db9-b82c-4720c69c2b84" token="14465dd9-b9ac-4e37-b64b-3c4c98154820"> extra=#<OmniAuth::AuthHash raw_info=#<OmniAuth::AuthHash description=nil email="nicolas.franck@ugent.be" first_name="Nicolas" last_name="Franck" name=nil other_names=[nil] urls=#<OmniAuth::AuthHash>>> info=#<OmniAuth::AuthHash::InfoHash description=nil email="nicolas.franck@ugent.be" first_name="Nicolas" last_name="Franck" name=nil urls=#<OmniAuth::AuthHash>> provider="orcid" uid="0000-0002-5268-9669">
=end

      auth = request.env['omniauth.auth'] || {}
      uid = auth.uid
      email = auth['info']['email']

      if email.present?
        user_with_email = User.where( :email => email ).first
      end

      if uid.present?

        user = User.where( :orcid_id => uid ).first
        @user = user

        if user.nil?

          user = !user_with_email.nil? ? user_with_email : User.new( )
          user.orcid_id = uid

        else

          email = user.email

        end

        user.email = email

        unless user.firstname.present?

          user.firstname = auth['info']['first_name']

        end
        unless user.surname.present?

          user.surname = auth['info']['last_name']

        end

        if user.new_record?

          user.ensure_password

        end

        unless user.valid?

          session[:sso_user] = user.writable_attributes
          redirect_to edit_sso_user_path, alert: user.errors.full_messages
          return

        else

          user.save

          #login
          flash[:notice] = I18n.t('devise.omniauth_callbacks.success', :kind => 'ORCID')

          sign_in user
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
      $stderr.puts "clearing invitation token for user #{ @user.email }"
      @user.accept_invitation! if @user.invitation_token.present?
    end
  end
end
