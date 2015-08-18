module Pig
  module ContentHelper

    def content_package_publish_at_class
      @content_package.status == 'published' && Pig::ContentPackage.statuses(current_user).has_key?(:published)  ? 'hidden' : ''
    end

    def needs_design(content_package)
      return nil unless content_package.missing_view?
      content_tag(:span, 'Needs design', :class => 'label label-default')
    end

    def parent_content_package_select(form, options = {})
      options.reverse_merge!(:label => "Parent")
      current_page = form.object
      return "" if Pig::ContentPackage.without([current_page] + current_page.children).empty?
      out = form.label(:parent_id, options[:label], :class => 'control-label')
      out << content_tag(:div, form.select(:parent_id, content_tag(:option, 'None', :value => '') + parent_content_package_option_tags(current_page)), :class => 'controls')
      # content_tag(:div, out, :class => 'select form-group optional', :id => 'content_package_parent_input')
    end

    def parent_content_package_option_tags(current_page, options = {})
      options.reverse_merge!(:pages => Pig::ContentPackage.root, :indent => 0)
      parent_pages = options[:pages].without([current_page] + current_page.children)
      parent_pages.inject('') do |memo, parent_page|
        ret = "<option value='#{parent_page.id}'"
        ret << " selected='selected'" if current_page.parent == parent_page
        ret << ">#{'&nbsp;&minus;&nbsp;' * options[:indent]}#{parent_page}</option>"
        if parent_page.children.present?
          ret << parent_content_package_option_tags(current_page, :pages => parent_page.children, :indent => options[:indent] + 1)
        end
        memo + ret
      end.html_safe
    end

    def sitemap_spacers(content_package, parents)
      "".tap do |out|
        parents.each_with_index do |parent, idx|
          spacer_class = 'spacer'
          if parent == parents.last
            if content_package == parent.children.last
              spacer_class << ' spacer-last'
            else
              spacer_class << ' spacer-mid'
            end
          else
            next_parent = parents[idx + 1]
            if next_parent && (next_parent == parent.children.last)
              spacer_class << ' spacer-empty'
            end
          end
          out << content_tag(:span, nil, :class => spacer_class, :title => parent.name)
        end
      end.html_safe
    end

    def status(status_string)
      case status_string
      when 'published' then 'Published'
      when 'pending' then 'Ready to review'
      else 'Draft'
      end
    end

  end
end
