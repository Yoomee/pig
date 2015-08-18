module Pig
  class ApplicationController < ::ApplicationController

    layout "pig/application"

    rescue_from CanCan::AccessDenied do |exception|
      if current_user
        redirect_to pig.not_authorized_path, alert: exception.message
      else
        redirect_to pig.new_user_session_path, alert: exception.message
      end
    end

    def not_authorized
    end

    protected

      def after_sign_in_path_for(resource)
        pig.root_path
      end

      def current_ability
        @current_ability ||= Pig::Ability.new(current_user)
      end

  end
end
