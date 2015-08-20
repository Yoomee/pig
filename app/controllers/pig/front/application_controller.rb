module Pig
  module Front
    class ApplicationController < ::ApplicationController

      protected

      def current_ability
        @current_ability ||= Pig::Ability.new(current_user)
      end

    end
  end
end
