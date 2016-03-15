class PasswordsController < Devise::PasswordsController
  before_filter :authenticate_user!

	protected

	def after_resetting_password_path_for(resource)
    root_path
  end
end
