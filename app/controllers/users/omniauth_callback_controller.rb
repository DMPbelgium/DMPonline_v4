class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

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
end
