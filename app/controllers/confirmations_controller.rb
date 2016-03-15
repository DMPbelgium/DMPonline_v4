class ConfirmationsController < Devise::ConfirmationsController
  before_filter :authenticate_user!
  protected

  def after_confirmation_path_for(resource_name, resource)
    root_path
  end

end
