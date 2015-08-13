module Pig
  class ImageType < Type
    def decorate(content_package)
      this = self
      slug = @slug
      field_type = @field_type
      super(content_package)

      content_package.define_singleton_method("#{@slug}_uid") do
        this.content_value(content_package)
      end

      content_package.define_singleton_method("#{@slug}_uid=") do |value|
        content_package.json_content['content_chunks'] ||= {}
        content_package.json_content['content_chunks'][slug] = {
          'value' => value,
          'field_type' => field_type
        }
        content_package.json_content_will_change! if Rails.version.to_f < 4.2
      end

      content_package.define_singleton_method("remove_#{@slug}") do
        send("#{slug}_uid=", nil)
      end
      content_package.define_singleton_method("remove_#{@slug}=") do |value|
        send("#{slug}_uid=", nil) if value == '1'
      end

      content_package.define_singleton_method("#{@slug}_alt") do
        content_package.json_content['content_chunks'] ||= {}
        content_package.json_content['content_chunks'][slug] ||= {}
        content_package.json_content['content_chunks'][slug]['alt'] || ''
      end

      content_package.define_singleton_method("#{@slug}_alt=") do |value|
        content_package.json_content['content_chunks'] ||= {}
        content_package.json_content['content_chunks'][slug] ||= {}
        content_package.json_content['content_chunks'][slug]['alt'] = value
        content_package.json_content_will_change! if Rails.version.to_f < 4.2
      end
    end

    def get(content_package)
      if super(content_package).blank?
        nil
      else
        job = Dragonfly.app.fetch(super(content_package))
        ImageDownloader.download_image_if_missing(job)
        job
      end
    end

    def set(content_package, value)
      if value.is_a?(String)
        temp_file = Tempfile.new('image')
        temp_file.write(value)
        temp_file.close
        uid = Dragonfly.app.fetch_file(temp_file.path).store
      else
        uid = Dragonfly.app.fetch_file(value.tempfile.path).store
      end
      super(content_package, uid)
    end
  end
end
