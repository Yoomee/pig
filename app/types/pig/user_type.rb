module Pig
  # Type which return nil instead of blank string
  class UserType < Type
    def decorate(content_package)
      this = self
      slug = @slug
      super(content_package)
      content_package.define_singleton_method("#{@slug}_id=") do |value|
        send("#{slug}=", value)
      end
      content_package.define_singleton_method("#{@slug}_id") do
        this.content_value(self)
      end
    end

    def set(content_package, value)
      if value.is_a?(Pig::User)
        super(content_package, value.id)
      else
        super(content_package, value)
      end
    end

    def get(content_package)
      id = content_value(content_package)
      return unless Pig::User.exists?(id)
      Pig::User.find(id)
    end
  end
end
