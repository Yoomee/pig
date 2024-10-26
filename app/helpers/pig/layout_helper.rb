include ActionView::Helpers::CaptureHelper

module Pig::LayoutHelper

  def body_tag(options = {}, &block)
    options[:id] ||= id_for_body_tag
    body_class = "#{classes_for_body_tag} #{options[:class]}".strip
    options[:class] = body_class unless body_class.blank?
    concat content_tag(:body, capture(&block), options)
  end

  def pig_admin_header(content_package)
    render 'layouts/pig/admin_links', content: content_package
  end

  private
  def id_for_body_tag
    is_home? ? 'home' : 'inside'
  end

  def is_home?
    @is_home || controller_name == "home"
  end

  def classes_for_body_tag
    [].tap do |classes|
      classes << "controller_#{controller_name}"
      classes << "action_#{action_name}"
      # classes << (current_user? ? 'logged_in' : 'logged_out')
      # classes << (current_user ? 'logged_in' : 'logged_out')
      # classes << (current_user ? "role-#{current_user.role}" : 'role-anonymous')
      classes << "root_slug_#{@page.root_slug}" if defined?(@page) && @page && @page.root && @page.root_slug.present?
      classes << "slug_#{@page.slug}" if defined?(@page) && @page && @page.slug.present?
    end.join(' ')
  end

end
