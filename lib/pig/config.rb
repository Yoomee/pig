module Pig
  class Config
    attr_accessor :nested_permalinks,
                  :tags_feature,
                  :basic_redactor_plugins,
                  :redactor_plugins,
                  :cms_roles,
                  :unpublished,
                  :not_found,
                  :additional_stylesheets,
                  :additional_javascripts,
                  :homepage,
                  :archive_domain,
                  :ga_code

    def initialize(options = {})
      self.nested_permalinks = options[:nested_permalinks] || true
      self.tags_feature = options[:tags_feature] || true
      self.basic_redactor_plugins = options[:basic_redactor_plugins] || []
      self.redactor_plugins = options[:redactor_plugins] || []
      self.unpublished = options[:unpublished] || proc { render template: 'pig/front/errors/not_found', layout: 'application', status: '404' }
      self.not_found = options[:not_found] || proc { render template: 'pig/front/errors/not_found', layout: 'application', status: '404' }
      self.additional_stylesheets = options[:additional_stylesheets] || []
      self.additional_javascripts = options[:additional_javascripts] || []
      self.homepage = options[:homepage] || proc { Pig::ContentPackage.first }
      self.archive_domain = options[:archive_domain] || ''
      self.ga_code = options[:ga_code] || ''
    end

  end
end
