module Pig
  class Engine < ::Rails::Engine
    isolate_namespace Pig

    ## Fix for Rails 7
    initializer 'pig.load_helpers' do
      # This ensures that we are targeting the engine's helpers directory
      helpers_path = config.root.join('app', 'helpers', 'pig', '**', '*.rb')
      Dir.glob(helpers_path).each do |file|
        puts "DEBUG: require_dependency(#{file})" # For debugging purposes
        require_dependency file
      end
    end

    config.to_prepare do
      Dir.glob(Rails.root + 'app/decorators/**/*_decorator*.rb').each do |c|
        require_dependency(c)
      end
      # Make all main app helpers available to the content packages controller
      # for use in the content type views
      Pig::Admin::ContentPackagesController.helper Rails.application.helpers
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end

    initializer 'pig.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper Pig::ApplicationHelper
        helper Pig::MetaTagsHelper
        helper Pig::LayoutHelper
        helper Pig::NavigationHelper
        helper Pig::ContentHelper
        helper Pig::TitleHelper
        helper Pig::ImageHelper
      end
    end
  end
end
