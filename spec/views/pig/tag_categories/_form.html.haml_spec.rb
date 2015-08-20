require 'rails_helper'

RSpec.describe "pig/admin/tag_categories/_form", type: :view do
  let(:tag_category) { FactoryGirl.create(:tag_category) }

  before(:each) do
    assign(:tag_category, tag_category)
    render
  end

  it "should have a name field" do
    expect(rendered).to have_xpath("//input[@name='tag_category[name]']")
  end

  it "should have a slug field" do
    expect(rendered).to have_xpath("//input[@name='tag_category[slug]']")
  end

  it "should have a name field" do
    expect(rendered).to have_xpath("//input[@name='tag_category[taxonomy_list][]']")
  end

end
