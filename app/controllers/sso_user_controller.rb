class SsoUserController < ApplicationController

  before_filter :require_authentication

  def edit

    @sso_user = session[:sso_user]
    render :edit

  end

  def update

    user_params = params[:user]

    if user_params.is_a?(Hash)

      #merge attributes
      session[:sso_user].merge!( user_params.slice(:firstname, :surname) )

      #update user or create new one
      user = User.find_by_email( session[:sso_user]["email"] ) || User.new()
      user.assign_attributes( session[:sso_user] )

      if user.valid?

        #clear invitation if it was present
        user.accept_invitation if user.invitation_token.present?
        user.save

        #sign in
        sign_in user
        redirect_to root_path

      else

        redirect_to edit_sso_user_path, :alert => user.errors.full_messages

      end

    else

      redirect_to edit_sso_user_path, :notice => I18n.t("sso_user.actions.no_changes")

    end

  end

private

  def require_authentication
    if user_signed_in?

      redirect_to root_path, :alert => I18n.t("sso_user.already_logged_in")

    elsif session[:sso_user].nil?

      redirect_to root_path, :alert => I18n.t("sso_user.not_authenticated")

    elsif !(session[:sso_user]["email"].present?)

      redirect_to root_path, :alert => I18n.t("sso_user.record.email.required")

    end
  end

end
