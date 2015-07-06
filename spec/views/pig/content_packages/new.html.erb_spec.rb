require 'rails_helper'

module Pig
  RSpec.describe "pig/content_packages/new", type: :view do
    it "should order requested by surname, regardless of role" do
      user_c = FactoryGirl.create(:user, :admin, last_name: 'C', first_name: 'C')
      user_b = FactoryGirl.create(:user, :admin, last_name: 'B', first_name: 'B')
      user_a = FactoryGirl.create(:user, :admin, last_name: 'A', first_name: 'A')
      assign(:content_package, Pig::ContentPackage.new)
      render
      assigned_to_options = Nokogiri::HTML(rendered)
        .xpath("//select[@id='content_package_requested_by_id']").text
      expect(assigned_to_options).to eq("\nA A\nB B\nC C")
    end
  end
end
