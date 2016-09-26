class EmailsController < ApplicationController
  before_filter :authenticate_user!

  def index

    authorize! :emails, User

    q = params[:q].strip
    limit = params[:limit].blank? ? 10 : params[:limit].to_i
    limit = 20 if limit > 20
    start = params[:start].blank? ? 0 : params[:start].to_i
    total = 0
    data = []

    unless q.blank?

      like_q = '%'+q+'%'
      users = User.where("email LIKE ? OR firstname LIKE ? OR surname LIKE ? OR orcid_id LIKE ?",like_q,like_q,like_q,like_q)
      users = users.order(:email).limit( limit )
      total = users.count
      data = users.offset( start).pluck(:email)

    end

    render :json => { :q => q, :start => start, :limit => limit, :data => data, :total => total }

  end

end
