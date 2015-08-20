module Pig
  module Admin
    class PasswordsController < Devise::PasswordsController
      layout 'pig/simple'
    end
  end
end
