class StaticPagesController < ApplicationController

  before_filter :authenticate_user!, :only => [ :contracts, :uploads ]

  def about_us
    @news_feed = Feedzirra::Feed.fetch_and_parse(ENV['DMP_FEED_URL'])
    respond_to do |format|
      format.rss { redirect_to ENV['DMP_FEED_URL'] }
      format.html
    end
  end

  def contact_us
  end

  def roadmap
  end

  def privacy
  end

  def contracts

    @uploads = Dir.entries( self.class.upload_base_dir() )
                  .select { |e| File.file?(e) }
                  .reject { |e| e.start_with?(".") }
                  .map { |e| File.basename(e) }

  end

  def uploads

    file = File.join( self.class.upload_base_dir, params[:file] )

    unless File.file?( file )

      raise CanCan::AccessDenied.new

    end

    send_file(file)

  end

private

  def self.upload_base_dir

    if @upload_base_dir.nil?

      @upload_base_dir = ENV["UPLOAD_BASE_DIR"]
      @upload_base_dir = @upload_base_dir.present? && File.directory?( @upload_base_dir ) ?
        @upload_base_dir : File.join( Rails.root, "uploads" )

    end

    @upload_base_dir

  end

end
