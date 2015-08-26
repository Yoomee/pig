$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "pig/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "pig"
  s.version     = Pig::VERSION
  s.authors     = ["Yoomee Developers"]
  s.email       = ["developers@yoomee.com"]
  s.homepage    = "http://yoomee.com"
  s.summary     = "The Yoomee CMS"
  s.description = ""
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'rails'
  s.add_dependency 'coffee-rails'
  s.add_dependency 'geocoder'
  s.add_dependency 'cocoon'
  s.add_dependency 'public_suffix'
  s.add_dependency 'stringex'
  s.add_dependency 'acts-as-taggable-on'
  s.add_dependency 'formtastic'
  s.add_dependency 'formtastic-bootstrap'
  s.add_dependency 'cancancan'
  s.add_dependency 'rack-cache'
  s.add_dependency 'dragonfly', '~>1.0'
  s.add_dependency 'dragonfly-s3_data_store'
  s.add_dependency 'devise'
  s.add_dependency 'haml-rails'
  s.add_dependency 'config', '~> 1.0.0'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-ui-rails'
  s.add_dependency 'bootstrap-sass'
  s.add_dependency 'will_paginate'
  s.add_dependency 'will_paginate-bootstrap'
  s.add_dependency 'cells'
  s.add_dependency 'cells-haml'
  s.add_dependency 'poltergeist'
  s.add_dependency 'httparty'
  s.add_dependency 'react-rails', '~> 1.0'
  s.add_dependency 'oauth2'
  s.add_dependency 'legato'
  s.add_dependency 'google-api-client'
  s.add_dependency 'awesome_nested_set'
  s.add_dependency "typhoeus"
  s.add_dependency "acts_as_commentable"
  s.add_dependency 'paper_trail', '~> 4.0.0'

  s.add_development_dependency "pg"
end
