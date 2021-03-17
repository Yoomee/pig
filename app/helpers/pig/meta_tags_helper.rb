module Pig
  module MetaTagsHelper

    def header_page_title
      meta_title, meta_description, meta_image, meta_keywords, meta_hide_from_robots = build_meta_values
      meta_title
    end

    # Takes an optional parameter of meta_values
    # If not provided meta_values are auto-generated where possible
    # Params:
    # meta_values  [meta_title, meta_description, meta_image, meta_keywords, meta_hide_from_robots]
    def pig_meta_tags(meta_values = nil)
      if meta_values.nil?
        meta_values = build_meta_values
      end
      meta_tags = build_meta_tags(meta_values)
      meta_tags.html_safe
    end

    # builds meta data needed for generating meta tags
    def build_meta_values
      page_slug = request.path.match(/^\/(.+)$/) { $1 }
      if @content_package
        # cache content_package_meta_tags_cache_key(@content_package) do

        meta_title = @content_package.meta_title.presence || Settings.default_meta_title
        meta_description = @content_package.meta_description.presence || Settings.default_meta_description
        meta_image = @content_package.meta_image_uid ? "#{Settings.site_url}#{@content_package.meta_image.thumb('300x300#').url}" : "#{Settings.site_url}#{image_path(Settings.default_fb_meta_image)}"
        meta_keywords = @content_package.meta_keywords.presence || Settings.default_meta_keywords

        if @content_package.hide_from_robots?
          meta_hide_from_robots = "<meta name='robots' content='noindex, nofollow' />\n"
        end
        [meta_title, meta_description, meta_image, meta_keywords, meta_hide_from_robots]
        # end
      elsif meta_data = Pig::MetaDatum.where(page_slug: page_slug).first
        meta_title = meta_data.title || Settings.default_meta_title
        meta_description = meta_data.description || Settings.default_meta_description
        meta_image = meta_data.image_uid ? "#{Settings.site_url}#{meta_data.image.thumb('300x300#').url}" : "#{Settings.site_url}#{image_path(Settings.default_fb_meta_image)}"
        meta_keywords = meta_data.keywords || Settings.default_meta_keywords
        [meta_title, meta_description, meta_image, meta_keywords, nil]
      end
    end

    # generates meta tags from data
    def build_meta_tags(meta_values, include_keywords = true)
      meta_title, meta_description, meta_image, meta_keywords, meta_hide_from_robots = meta_values
      meta_tags = meta_hide_from_robots.to_s
      # build actual tags from values

      if meta_image.present?
        meta_tags << "<meta name=\"twitter:card\" content=\"photo\">\n"
      else
        meta_tags << "<meta name=\"twitter:card\" content=\"summary\">\n"
      end

      if meta_title.present?
        meta_tags << "<meta itemprop=\"name\" content=\"#{meta_title}\">\n"
        meta_tags << "<meta name=\"twitter:title\" content=\"#{meta_title}\">\n"
        meta_tags << "<meta property=\"og:title\" content=\"#{meta_title}\" />\n"
      end

      if meta_description.present?
        meta_tags << "<meta name=\"description\" content=\"#{meta_description}\">\n"
        meta_tags << "<meta itemprop=\"description\" content=\"#{meta_description}\">\n"
        meta_tags << "<meta name=\"twitter:description\" content=\"#{meta_description}\">\n"
        meta_tags << "<meta property=\"og:description\" content=\"#{meta_description}\" />\n"
      end

      if meta_image.present?
        meta_tags << "<meta itemprop=\"image\" content=\"#{meta_image}\">\n"
        meta_tags << "<meta property=\"og:image\" content=\"#{meta_image}\"/>\n"
      end

      if meta_keywords.present? && include_keywords
        meta_tags << "<meta name=\"keywords\" content=\"#{meta_keywords}\">\n"
      end

      meta_tags << "<meta property=\"og:url\" content=\"#{request.original_url}\" />\n"
      meta_tags << "<meta property=\"twitter:url\" content=\"#{request.original_url}\" />\n"
      meta_tags << "<meta property=\"og:site_name\" content=\"#{Settings.site_name}\"/>\n"
      meta_tags << "<meta property=\"og:type\" content=\"article\"/>\n"

      meta_tags
    end

    def ga_code?
      ga_code.present?
    end

    def ga_code
      Pig.configuration.ga_code
    end

  end
end
