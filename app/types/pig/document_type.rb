module Pig
    class DocumentType < Type
      def decorate(content_package)
        this = self
        super(content_package)
        content_package.define_singleton_method("#{@slug}_file") do
          id = this.content_value(self)
          return false unless Trough::Document.exists?(id)
          Trough::Document.find(id)
        end
      end
    end
  end