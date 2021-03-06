class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_user

  #Override build_footer method in ActiveAdmin::Views::Pages
  require 'active_admin_views_pages_base.rb'

  rescue_from CanCan::AccessDenied do |exception|
    #cf. https://github.com/ryanb/cancan/wiki/Exception-Handling
    #'message' can be changed in config/locales/en.yml
    render :text => exception.message ,:status => 403
  end
  rescue_from ActiveRecord::RecordNotFound do |exception|
    render :text => "You are not authorized to access this page.", :status => 403
  end

 	after_filter :store_location

	def store_location
	  # store last url - this is needed for post-login redirect to whatever the user last visited.
		if (request.fullpath != "/users/sign_in" && \
		  request.fullpath != "/users/sign_up" && \
			request.fullpath != "/users/password" && \
      request.fullpath != "/users/sign_up?nosplash=true" && \
			!request.xhr?) # don't store ajax calls
		  session[:previous_url] = request.fullpath
    end
	end

	def after_sign_in_path_for(resource)
	  session[:previous_url] || root_path
	end

	def after_sign_up_path_for(resource)
	  session[:previous_url] || root_path
	end

	def after_sign_in_error_path_for(resource)
	  session[:previous_url] || root_path
	end

	def after_sign_up_error_path_for(resource)
	  session[:previous_url] || root_path
	end

	def authenticate_admin!
		raise CanCan::AccessDenied.new unless user_signed_in? && current_user.is_admin?
	end

	def get_plan_list_columns
		if user_signed_in?
			@selected_columns = current_user.settings(:plan_list).columns
			@all_columns = Settings::PlanList::ALL_COLUMNS
		end
	end

  def set_user
    User.current_user = current_user
  end

end
