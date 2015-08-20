require 'rails_helper'

RSpec.describe "pig/admin/content_types/_content_attribute_fields", type: :view do
  before(:each) do
    content_type = FactoryGirl.build(:content_type)
    assign(:content_type, content_type)
    form_builder = FormtasticBootstrap::FormBuilder.new('content_type[content_attributes_attributes]', content_type.content_attributes.first, template, {index: 0})
    render partial: 'pig/admin/content_types/content_attribute_fields', locals: { f: form_builder }
  end

  it 'should have a name input' do
    expect(rendered).to have_xpath('//input[@name="content_type[content_attributes_attributes][0][name]"]')
  end

  it 'should have a type select' do
    expect(rendered).to have_xpath('//select[@name="content_type[content_attributes_attributes][0][field_type]"]')
  end

  it 'should have a description text area' do
    expect(rendered).to have_xpath('//textarea[@name="content_type[content_attributes_attributes][0][description]"]')
  end

  it 'should have a \'required\' checkbox' do
    expect(rendered).to have_xpath('//input[@name="content_type[content_attributes_attributes][0][required]"]')
  end

  it 'should have a meta attribute checkbox' do
    expect(rendered).to have_xpath('//input[@name="content_type[content_attributes_attributes][0][meta]"]')
  end
end
