class UserMailer < ActionMailer::Base
	default from: ENV['DMP_USER_MAILER_EMAIL_FROM']

  def sharing_notification(project_group)
		@project_group = project_group
		mail(to: @project_group.user.email, subject: "You have been given access to a Data Management Plan")
	end

	def permissions_change_notification(project_group)
		@project_group = project_group
		mail(to: @project_group.user.email, subject: "DMP permissions changed")
	end

	def project_access_removed_notification(user, project)
		@user = user
		@project = project
		mail(to: @user.email, subject: "DMP access removed")
	end

  def report_new_user(user)
    @user = user
    mail(
      :to => User.joins(:roles).where(:roles => { :name => "admin" }).all.map(&:email),
      :subject => "new user #{user.email} added"
    )
  end
end
