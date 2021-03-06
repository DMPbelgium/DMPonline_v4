class ConfirmationsController < Devise::ConfirmationsController
  #before_filter :authenticate_user!
  before_filter :force_relogin, :only => [ :show, :update ]

  def force_relogin

    sign_out :user if user_signed_in?

  end

  def after_confirmation_path_for(resource_name, resource)
    root_path
  end

  def show

    #no access without confirmation_token
    if !( params[:confirmation_token].present? && params[:confirmation_token].is_a?(String) )

      flash[:alert] = I18n.t("devise.confirmations.confirmation_token_needed")
      redirect_to root_path
      return

    end

    @user = User.where( :confirmation_token => params[:confirmation_token] ).first

    #no user found for confirmation_token
    if @user.nil?

      flash[:alert] = I18n.t("devise.confirmations.confirmation_token_invalid")
      redirect_to root_path
      return

    end

    #user not confirmable anymore
    if @user.confirmed?

      flash[:alert] = I18n.t("devise.confirmations.already_confirmed")
      redirect_to root_path
      return

    end

    if @user.nemo? || @user.orcid_id.blank?

      render :action => :show
      return

    end

    #user already ok, but confirmation needed (case: reconfirmation instructions sent at the users request)
    super

  end

  def update

    p = params.permit( :confirmation_token, :firstname, :surname )

    unless p[:confirmation_token].is_a?(String)

      flash[:alert] = I18n.t("devise.confirmations.confirmation_token_needed")
      redirect_to root_path
      return

    end

    @user = User.where( :confirmation_token => p[:confirmation_token] ).first

    if @user.nil?

      flash[:alert] = I18n.t("devise.confirmations.confirmation_token_invalid")
      redirect_to root_path
      return

    end

    if @user.confirmed?

      flash[:alert] = I18n.t("devise.confirmations.already_confirmed")
      redirect_to root_path
      return

    end

    p[:firstname] = "" if p[:firstname] == User.nemo
    p[:surname] = "" if p[:surname] == User.nemo

    errors = []
    errors << "firstname not given" if p[:firstname].length <= 0
    errors << "surname not given" if p[:surname].length <= 0

    if errors.length > 0

      flash[:alert] = errors
      render :action => :show
      return

    else

      #user created by first time login with orcid:
      # orcid_id: present
      # firstname: todo
      # surname: todo
      if @user.orcid_id.present?

        @user.assign_attributes(p.slice(:firstname,:surname))
        @user.confirm!

        sign_in @user
        redirect_to edit_user_registration_path

      else

        session[:confirm_user] = {
          :confirmation_token => p[:confirmation_token],
          :firstname => p[:firstname],
          :surname => p[:surname]
        }
        redirect_to user_omniauth_authorize_url(:orcid)
        return

      end

    end

  end

end
