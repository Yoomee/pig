module Pig
  module Front
    class ContentPackagesController < Pig::Front::ApplicationController

      load_and_authorize_resource class: 'Pig::ContentPackage'
      skip_load_resource only: [:home]

      around_action :redirect_to_permalink, only: [:show]

      rescue_from CanCan::AccessDenied do |exception|
        instance_eval(&Pig.configuration.unpublished)
      end

      def home
        @content_package = instance_eval(&Pig.configuration.homepage)
        render_content_package_view
      end

      def show
        render_content_package_view
      end

      private

      def render_content_package_view
        return if @content_package.missing_view?
        render "pig/templates/#{@content_package.view_name}"
      end

      def redirect_to_permalink
        # If the url matched a permalinkable content package route then it will have a param of :path
        if params[:path]
          if permalink = Permalink.find_from_url(params[:path])
            #If the permalink is active then just set the content package and yield to the original action.
            if permalink.active
              @content_package = Pig::ContentPackage.includes(:content_chunks => :content_attribute).find(permalink.resource_id)
              authorize! params[:action].to_sym, @content_package
              yield
            else
              # Otherwise redirect to the proper permalink so that we come back to this method and fall through the correct path.
              redirect_to pig.content_package_path(permalink.resource.permalink) + params_for_redirect, status: 301
            end
          else
            # If there isn't a matching permalink handle it with rails (Default is 404)
            raise ::ActiveRecord::RecordNotFound.new
          end
        else
          if (@content_package && @content_package.permalink.nil?) || Pig::ContentPackage.member_routes.reject { |x| x[:action] == "show" }.any?{|x| x[:action] == params[:action]}
            yield
          else
            redirect_to @content_package.permalink.full_path + params_for_redirect, status: 301
          end
        end
      end

      def params_for_redirect
        significant_params = params.except(:action, :controller, :id, :path)
        significant_params.present? ? '?' + significant_params.to_query : ''
      end

    end
  end
end
