require 'rails_helper'

RSpec.describe "pig/admin/tag_categories/new", type: :view do
  before(:each) do
    assign(:tag_category, Pig::TagCategory.new)
  end

  it "renders new tag_category form" do
    render

    assert_select "form[action=?][method=?]", pig.admin_tag_categories_path, "post" do
    end
  end
end
