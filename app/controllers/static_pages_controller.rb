class StaticPagesController < ApplicationController

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

end
