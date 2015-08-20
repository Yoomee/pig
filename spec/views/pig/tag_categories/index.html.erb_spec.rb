require 'rails_helper'

RSpec.describe 'pig/admin/tag_categories/index', type: :view do
  let(:tag_category_1) { FactoryGirl.create(:tag_category, name: 'Foo') }
  let(:tag_category_2) { FactoryGirl.create(:tag_category, name: 'Bar') }

  before(:each) do
    assign(:tag_categories, [
      tag_category_1,
      tag_category_2
    ])
    render
  end

  it 'renders a list of tag_categories' do
    expect(rendered).to have_text('Foo')
    expect(rendered).to have_text('Bar')
  end

  it 'has a link to create a new tag category' do
    expect(rendered).to have_link('New Tag Category', href: pig.new_admin_tag_category_path)
  end

  it 'has a link to edit a tag category' do
    expect(rendered).to have_link('Foo', href: pig.edit_admin_tag_category_path(tag_category_1))
    expect(rendered).to have_link('Bar', href: pig.edit_admin_tag_category_path(tag_category_2))
  end
end
