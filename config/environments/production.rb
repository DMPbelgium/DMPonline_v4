DMPonline4::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

	# Add the fonts path
	config.assets.paths << Rails.root.join('app', 'assets', 'fonts', 'videos')

	# Precompile additional assets
	config.assets.precompile += %w( .svg .eot .woff .ttf )


  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  config.cache_store = :memory_store, { size: 64.megabytes }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true

  #devise config
  unless ENV['DMP_HOST'].blank? || ENV['DMP_SMTP_ADDRESS'].blank? || ENV['DMP_SMTP_PORT'].blank? || ENV['DMP_EMAIL_FROM'].blank? || ENV['DMP_SMTP_ADDRESS'].blank? || ENV['DMP_SMTP_PORT'].blank?
    config.action_mailer.default_url_options[:host] = ENV['DMP_HOST']
    config.action_mailer.default_url_options[:protocol] = "https"
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = { :address => ENV['DMP_SMTP_ADDRESS'], :port => ENV['DMP_SMTP_PORT'] }

    ActionMailer::Base.default :from => ENV['DMP_EMAIL_FROM']
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = { :address => ENV['DMP_SMTP_ADDRESS'], :port => ENV['DMP_SMTP_PORT'] }
  end

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

	 # Error notifications by email
   unless ENV['DMP_ERR_EMAIL_PREFIX'].blank? || ENV['DMP_ERR_EMAIL_SENDER_ADDRESS'].blank? || ['DMP_ERR_EMAIL_EXCEPTION_RECIPIENTS'].blank?
     config.middleware.use ExceptionNotification::Rack,
      :email => {
        :email_prefix => ENV['DMP_ERR_EMAIL_PREFIX'],
        :sender_address => ENV['DMP_ERR_EMAIL_SENDER_ADDRESS'],
        :exception_recipients => JSON.parse(ENV['DMP_ERR_EMAIL_EXCEPTION_RECIPIENTS'])
      }
   end

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
end
