class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  after_filter :clear_invitation

  def shibboleth

    #user already signed in: return to profile
    if user_signed_in?

      redirect_to root_path
      return

    end

    auth = request.env['omniauth.auth'] || {}
    uid = auth.uid

    #no auth.uid present. Does this happen?
    if uid.blank?

      redirect_to root_path
      return

    end

    shibboleth_data = auth['extra']['raw_info']

    uid = uid.downcase if ENV['SHIBBOLETH_UID_LOWERCASE'] == "true"

    @user = User.where(shibboleth_id: uid).first

    #user found: update info and sign in
    if @user

      #clear confirmation
      @user.confirm! unless @user.confirmed?

      #update shibboleth data
      @user.update_attribute('shibboleth_data',shibboleth_data.to_json)

      @user.call_after_auth_shibboleth(auth,request)

      #sign in user
      sign_in @user

      #redirect to new root_path
      flash[:notice] = I18n.t('devise.omniauth_callbacks.success', :kind => 'Shibboleth')
      redirect_to root_path
      return

    end

    #create new user
    mail_field = ENV['SHIBBOLETH_MAIL_FIELD'].present? ? ENV['SHIBBOLETH_MAIL_FIELD'] : :mail
    email = auth['extra']['raw_info'][mail_field].present? ? auth['extra']['raw_info'][mail_field] : nil

    @user = User.new(
      :shibboleth_id => uid,
      :shibboleth_data => shibboleth_data.to_json,
      :email => email.downcase
    )

    #ensure password
    @user.ensure_password

    #validate
    unless @user.valid?

      flash[:alert] = @user.errors.full_messages
      redirect_to root_path
      return

    end

    #skip confirmation
    @user.skip_confirmation!
    @user.save

    #login
    flash[:notice] = I18n.t('devise.omniauth_callbacks.success', :kind => 'Shibboleth')

    @user.call_after_auth_shibboleth(auth,request)

    sign_in @user

    #redirect new user to profile page
    redirect_to edit_user_registration_path

  end

  def orcid

    auth = request.env['omniauth.auth'] || {}

    if auth.uid.blank?

      redirect_to root_path
      return

    end

    #link orcid to logged in user
    if user_signed_in?

      current_user.orcid_id = auth.uid

      if current_user.valid?

        flash[:notice] = I18n.t("devise.omniauth_callbacks.orcid.linked")
        current_user.save

      else

        flash[:alert] = current_user.errors.full_messages

      end

      redirect_to edit_user_registration_path
      return

    end

    #link orcid to confirmable user
    if session[:confirm_user].present? && session[:confirm_user].is_a?(Hash)

      u = User.where( :confirmation_token => session[:confirm_user][:confirmation_token] ).first

      if u && !u.confirmed?

        u.firstname = session[:confirm_user][:firstname]
        u.surname = session[:confirm_user][:surname]
        u.orcid_id = auth.uid

        u.confirm!

        session.delete(:confirm_user)

        sign_in u
        flash[:notice] = I18n.t("devise.omniauth_callbacks.orcid.linked")
        redirect_to edit_user_registration_path
        return

      end

    end

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

    email = auth['info']['email']
    @user = nil

    selectable_users = User.where( :orcid_id => auth.uid ).all

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

    #user found with email
    elsif email.present? && User.where( :email => email ).first

      #don't match this: multiple orcid records with same email available. This would make it possible
      #to log in to the same user using different orcid records..

      #unable to trust this user
      redirect_to root_path, :alert => I18n.t("devise.omniauth_callbacks.orcid.link")
      return

    #NEW USER. We trust "email" because ORCID marks it as confirmed
    elsif email.present?

      @user = User.new(
        :email => email,
        :orcid_id => auth.uid,
        :firstname => auth['info']['first_name'],
        :surname => auth['info']['last_name']
      )
      @user.skip_confirmation!
      @user.ensure_password

    else

      flash[:alert] = I18n.t('devise.omniauth_callbacks.failure', :kind => 'ORCID', :reason => 'could not retrieve email address. Please check the visibility settings in ORCID')
      redirect_to root_path
      return

    end

    is_new = @user.new_record?

    #just save record and login
    @user.save

    #login
    flash[:notice] = I18n.t('devise.omniauth_callbacks.success', :kind => 'ORCID')

    sign_in @user
    redirect_to( is_new ? edit_user_registration_path : root_path )

  end

private
  def clear_invitation
    unless @user.nil?
      @user.accept_invitation! if @user.invitation_token.present?
    end
  end
end
