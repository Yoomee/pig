module Pig
  module ContentHelper

    def content_package_publish_at_class
      @content_package.status == 'published' && Pig::ContentPackage.statuses(current_user).has_key?(:published)  ? 'hidden' : ''
    end

    def needs_design(content_package)
      return nil unless content_package.missing_view?
      content_tag(:span, 'Needs design', :class => 'label label-default')
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
