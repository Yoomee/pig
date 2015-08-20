# Require devise before engine to override views in engine
require 'devise'

require 'pig/engine'
require 'pig/config'
require 'stringex'
require 'formtastic-bootstrap'
require 'rack/cache'
require 'dragonfly'
require 'geocoder'
require 'acts-as-taggable-on'
require 'cancancan'
require 'haml-rails'
require 'config'
require 'cocoon'
require 'jquery-rails'
require 'jquery-ui-rails'
require 'bootstrap-sass'
require 'will_paginate'
require 'will_paginate-bootstrap'
require 'formtastic'
require 'cells'
require 'cells-haml'
require 'httparty'
require 'react-rails'
require 'oauth2'
require 'legato'
require 'google/api_client'
require 'awesome_nested_set'

require 'pig/link'
require 'pig/permalinkable'
require 'pig/archive'
require 'pig/core/plugins'
require 'pig/core/image_downloader'
require 'pig/metrics/visits'

# Concerns
require 'pig/concerns/models/core'
require 'pig/concerns/models/roles'
require 'pig/concerns/models/name'

module Pig
  class << self
    attr_writer :configuration
  end

  module_function

  def configuration
    @configuration ||= Config.new
  end

  def setup
    yield(configuration)
  end

  class UnknownAttributeTypeError < NameError
  end
end
