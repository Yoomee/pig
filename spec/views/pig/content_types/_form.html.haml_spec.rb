require 'rails_helper'

RSpec.describe "pig/admin/content_types/_form", type: :view do
  let(:content_type) { FactoryGirl.create(:content_type) }
  let(:tag_categories) { [FactoryGirl.create(:tag_category), FactoryGirl.create(:tag_category)] }

  before(:each) do
    assign(:content_type, content_type)
    assign(:tag_categories, tag_categories)
  end

  context 'as an admin' do
    before(:each) do
      ability = Pig::Ability.new(FactoryGirl.create(:user, :admin))
      allow(controller).to receive(:current_ability).and_return(ability)
      render
    end

    it 'should have a name field' do
      expect(rendered).to have_xpath("//input[@name='content_type[name]']")
    end

    it 'should not have a description field' do
      expect(rendered).to_not have_xpath("//textarea[@name='content_type[description]']")
    end

    it 'should not have a package name field' do
      expect(rendered).to_not have_xpath("//input[@name='content_type[package_name]']")
    end

    it 'should not have a view name field' do
      expect(rendered).to_not have_xpath("//input[@name='content_type[view_name]']")
    end

    it 'should not have a viewless checkbox' do
      expect(rendered).to_not have_xpath("//input[@name='content_type[viewless]']")
    end

    it 'should not have a singleton checkbox' do
      expect(rendered).to_not have_xpath("//input[@name='content_type[singleton]']")
    end

    it "should have tag a category checkbox for each tag category" do
      tag_categories.each do |tc|
        expect(rendered).to have_xpath("//input[@name='content_type[tag_category_ids][]' and @value='#{tc.id}']")
      end
    end
  end

  context 'as a developer' do
    before(:each) do
      ability = Pig::Ability.new(FactoryGirl.create(:user, :developer))
      allow(controller).to receive(:current_ability).and_return(ability)
      render
    end

    it 'should have a description field' do
      expect(rendered).to have_xpath("//textarea[@name='content_type[description]']")
    end

    it 'should have a package name field' do
      expect(rendered).to have_xpath("//input[@name='content_type[package_name]']")
    end

    it 'should have a view name field' do
      expect(rendered).to have_xpath("//input[@name='content_type[view_name]']")
    end

    it 'should have a viewless checkbox' do
      expect(rendered).to have_xpath("//input[@name='content_type[viewless]']")
    end

    it 'should have a singleton checkbox' do
      expect(rendered).to have_xpath("//input[@name='content_type[singleton]']")
    end
  end

end
