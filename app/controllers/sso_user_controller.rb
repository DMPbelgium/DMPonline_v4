class SsoUserController < ApplicationController

  before_filter :require_authentication

  def edit

    @sso_user = session[:sso_user]
    render :edit

  end

  def update

    user_params = params["user"]

    unless user_params.is_a? Hash
      raise ArgumentError.new("sso_user is required")
    end

    user = nil
    unless user_params["email"].nil?
      user = User.find_by_email( user_params["email"] )
    end
    user = user.nil? ? User.new : user

    user_params = user_params.slice( * user.writable_attributes.keys  )
    session[:sso_user].merge!( user_params )
    user.assign_attributes( session[:sso_user] )
    user.ensure_password

    if user.valid?

      #clear invitation if it was present
      user.accept_invitation if user.invitation_token.present?

      user.save
      sign_in user
      redirect_to root_path

    else

      redirect_to edit_sso_user_path, alert: user.errors.full_messages

    end

  end

private

  def require_authentication

    if user_signed_in?

      redirect_to root_path

    elsif session[:sso_user].nil?

      redirect_to new_user_registration_path

    end

  end

end
