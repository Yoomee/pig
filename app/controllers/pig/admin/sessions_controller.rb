module Pig
  module Admin
    class SessionsController < Devise::SessionsController
      layout 'pig/simple'
    end
  end
end
