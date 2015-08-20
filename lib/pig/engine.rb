module Pig
  class Engine < ::Rails::Engine
    isolate_namespace Pig

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

    initializer 'pig.action_controller' do
      ActiveSupport.on_load :action_controller do
        helper Pig::ApplicationHelper
        helper Pig::MetaTagsHelper
        helper Pig::LayoutHelper
        helper Pig::NavigationHelper
        helper Pig::ContentHelper
        helper Pig::TitleHelper
        helper Pig::ImageHelper
        helper Pig::CacheHelper
      end
    end
  end
end
