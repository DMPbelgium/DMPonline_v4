class ContactsController < ContactUs::ContactsController
  skip_before_filter :authenticate_user!
	def create
		@contact = ContactUs::Contact.new(params[:contact_us_contact])
		if (!user_signed_in?)

      if @contact.valid?

        if verify_recaptcha(:model => @contact, :message => "You have not added the validation words correctly") && @contact.save

          flash[:notice] = t('contact_us.notices.success')
          if user_signed_in? then
            redirect_to :controller => 'projects', :action => 'index'
          else
            redirect_to(root_path)
          end

        else

          flash[:alert] = @contact.errors.full_messages
          render_new_page

        end

			else

			  flash[:alert] = @contact.errors.full_messages
			  render_new_page

			end
		else
			if @contact.save
				flash[:notice] = t('contact_us.notices.success')
				if user_signed_in? then
			    redirect_to :controller => 'projects', :action => 'index'
		    else
			    redirect_to(root_path)
			  end
			else
			  flash[:alert] = @contact.errors.full_messages
			  render_new_page
			end
		end
	end
end
