require 'rails_helper'

RSpec.describe "pig/admin/tag_categories/edit", type: :view do
  before(:each) do
    @tag_category = assign(:tag_category, FactoryGirl.create(:tag_category))
  end

  it "renders the edit tag_category form" do
    render

    assert_select "form[action=?][method=?]", pig.admin_tag_category_path(@tag_category), "post" do
    end
  end
end
