module Pig
  module Front
    class ErrorsController < Pig::Front::ApplicationController
      def not_found
        render status: :not_found
      end
    end
  end
end
