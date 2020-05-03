class SwitchUserController < ApplicationController

  before_filter :authenticate_user!

  def edit

    @users = current_user.alternative_accounts()

    render :edit

  end

  def update

    user_params = params.require(:user).permit( :id )

    user_id = user_params[:id].to_i

    @users = current_user.alternative_accounts()

    user_index = @users.index { |u| u.id == user_id }

    if user_index

      user = @users[user_index]
      user.confirm! unless user.confirmed?
      sign_in user
      redirect_to root_path

    else

      redirect_to edit_switch_user_path, :alert => "Invalid user selected"

    end

  end

end
