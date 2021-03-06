require 'uri'

module ApplicationHelper
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files) }
  end

  def link_to_add_object(name, f, association, css_class, i)
    new_object = f.object.class.reflect_on_association(association).klass.new
    j = i
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      j = j + 1
      new_object.number = j
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, "add_object(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :class => css_class)
  end

  def set_url_query(url,params = [])
    uri = URI(url)
    form = URI.decode_www_form(uri.query || '') + params
    uri.query = URI.encode_www_form(form)
    uri.to_s
  end
  def get_shibboleth_login_links(default_url)
    login_links = []
    WayflessEntity.all.each do |we|

      url = set_url_query(default_url,[[:idp,we.url]])
      abbrev = we.name
      label_base = I18n.t('helpers.institution_sign_in_link_base')
      label = label_base.nil? ? "Sign in with #{abbrev}" : label_base+" "+abbrev
      login_links << [label,url]

    end
    login_links.sort { |a,b| a[0] <=> b[0] }
  end
end
