module Pig
  class Archive

    def self.active?
      self.domain.present?
    end

    def initialize(path)
      @path = path
    end

    def exists?
      HTTParty.get(uri).success?
    end

    def uri
      Pig::Archive.domain + @path
    end

    private

    def self.domain
      Pig.configuration.archive_domain
    end

  end
end
