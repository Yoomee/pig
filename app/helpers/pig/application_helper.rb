module Pig
  module ApplicationHelper

    require 'diffy'

    # Gets page title - uses long_page_title, etc if meta_title not set. If neither, or not a pig page, uses default.
    def get_meta_title
      meta_title = Settings.default_meta_title

      if @content_package && get_content_package_title
        meta_title = "#{get_content_package_title} | #{Settings.default_meta_title}"
      elsif content_for(:title)
        meta_title = "#{content_for(:title)} | #{Settings.default_meta_title}"
      end

      meta_title
    end

    # Gets meta tags - uses pig values or default except for meta image
    # Uses the hero image if no meta image is set. If neither, or not a pig page, uses default
    def get_meta_tags
      if @content_package

        if @content_package.meta_image_uid
          image = "#{Settings.site_url}#{@content_package.meta_image.thumb('1200x630#').url}"
        elsif @content_package.respond_to?(:hero_image) && @content_package.hero_image.present?
          image = "#{Settings.site_url}#{@content_package.hero_image.thumb('1200x630#').url}"
        end

        meta_title = @content_package.meta_title.presence || Settings.default_meta_title
        meta_description = @content_package.meta_description.presence || Settings.default_meta_description
        meta_keywords = @content_package.meta_keywords.presence || Settings.default_meta_keywords
        if @content_package.hide_from_robots?
          meta_hide_from_robots = "<meta name='robots' content='noindex, nofollow' />\n"
        end

      else
        meta_title = content_for(:title) || Settings.default_meta_title
        meta_description = content_for(:description) || Settings.default_meta_description
        meta_keywords = content_for(:keywords) || Settings.default_meta_keywords
        meta_hide_from_robots = nil
      end

      meta_description = strip_tags CGI.unescapeHTML(meta_description.strip)

      meta_image = image || content_for(:meta_image) || "#{Settings.site_url}#{asset_path(Settings.default_fb_meta_image)}"

      meta_values = [meta_title, meta_description, meta_image, meta_keywords, meta_hide_from_robots]

      pig_meta_tags(meta_values)
    end

    def show_diff(string1, string2)
      Diffy::Diff.new(string1, string2).to_s(:html)
    end

    def diffy_css
      "
      .diff{overflow:auto;}
      .diff ul{background:#fff;overflow:auto;font-size:13px;list-style:none;margin:0;padding:0;display:table;width:100%;}
      .diff del, .diff ins{display:block;text-decoration:none;}
      .diff li{padding:0; display:table-row;margin: 0;height:1em;}
      .diff li.ins{background:#dfd; color:#080}
      .diff li.del{background:#fee; color:#b00}
      /* try 'whitespace:pre;' if you don't want lines to wrap */
      .diff del, .diff ins, .diff span{white-space:pre-wrap;font-family:courier;}
      .diff del strong{font-weight:normal;background:#fcc;}
      .diff ins strong{font-weight:normal;background:#9f9;}
      .diff li.diff-comment { display: none; }
      .diff li.diff-block-info { background: none repeat scroll 0 0 gray; }
      "

    end

    def seconds_to_display(seconds)
      seconds = seconds.to_i
      minutes = seconds / 60
      remaining_seconds = seconds % 60
      "#{minutes}m #{remaining_seconds}s"
    end

    private

    def get_content_package_title
      if @content_package.meta_title.present?
        @content_package.meta_title
      elsif @content_package.respond_to?(:long_page_title)
        @content_package.long_page_title
      elsif @content_package.respond_to?(:title)
        @content_package.title
      elsif @content_package.respond_to?(:page_title)
        @content_package.page_title
      elsif @content_package.respond_to?(:heading)
        @content_package.heading
      end
    end
  end
end
