class Internal::ExportsController < ActionController::Base

  before_filter :http_authenticate

  def show_link

    file = File.join(
      @organisation.internal_export_dir,
      params[:name] + ".json"
    )

    if File.exists?(file)

      send_file file, :type => "application/json; charset=utf-8", :disposition => "inline"

    else

      file_not_found()

    end

  end

  def show_file

    file = File.join(
      @organisation.internal_export_dir,
      params[:year],
      params[:month],
      params[:name] + ".json"
    )

    if File.exists?(file)

      send_file file, :type => "application/json; charset=utf-8", :disposition => "inline"

    else

      file_not_found()

    end

  end

private

  def file_not_found

    render :json => {
      :errors => [{
        :status => "404",
        :id     => "file_not_found",
        :title  => "file not found"
      }]
    }, :status => 404

  end

  def http_authenticate

    authenticate_or_request_with_http_basic do |username, password|

      org = organisation()

      org.nil? ? false : RestUser.verify_and_load(org,username,password)

    end

  end

  def organisation

    @organisation ||= Organisation
      .where( :abbreviation => params[:organisation] )
      .first()

  end

end
