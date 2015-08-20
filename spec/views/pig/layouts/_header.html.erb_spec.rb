require 'rails_helper'

module Pig
  RSpec.describe "layouts/pig/_header", type: :view do

    it "should have a link to Account settings" do
      user = FactoryGirl.create(:user, role: 'admin')
      allow_any_instance_of(Devise::Controllers::Helpers).to receive(:current_user).and_return(user)
      render
      expect(rendered).to have_link("Account settings", href: pig.edit_admin_manage_user_path(user))
    end
  end
end
