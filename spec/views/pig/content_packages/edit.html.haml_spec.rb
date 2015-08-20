require 'rails_helper'

module Pig
  RSpec.describe 'pig/admin/content_packages/edit', type: :view do
    let(:admin) { FactoryGirl.create(:user, :admin, last_name: 'A', first_name: 'A') }

    before(:each) do
      assign(:non_meta_content_attributes, [])
      assign(:persona_groups, [])
      assign(:activity_items, instance_double('ActivityItems',
                                              total_pages: 0,
                                              current_page: 1))
      assign(:content_package, FactoryGirl.create(:content_package,
                                                  author: admin,
                                                  requested_by: admin,
                                                  editing_user: admin))
      allow(view).to receive(:current_user).and_return(admin)
      @ability = Ability.new(admin)
      allow(controller).to receive(:current_ability).and_return(@ability)
    end

    it 'should order assigned to by surname, regardless of role' do
      FactoryGirl.create(:user, :admin, last_name: 'C', first_name: 'C')
      FactoryGirl.create(:user, :author, last_name: 'B', first_name: 'B')
      render
      assigned_to_options = Nokogiri::HTML(rendered)
        .xpath("//select[@id='content_package_author_id']").text
      expect(assigned_to_options).to eq("\nA A (admin)\nB B (author)\nC C (admin)")
    end

    it 'should order requested_by by surname' do
      FactoryGirl.create(:user, :admin, last_name: 'C', first_name: 'C')
      FactoryGirl.create(:user, :admin, last_name: 'B', first_name: 'B')
      render
      assigned_to_options = Nokogiri::HTML(rendered)
        .xpath("//select[@id='content_package_requested_by_id']")
        .text
      expect(assigned_to_options).to eq("\nA A\nB B\nC C")
    end

    context 'signed in as a developer' do
      let(:developer) { FactoryGirl.create(:user, :developer) }

      before(:each) do
        @ability = Ability.new(developer)
        allow(controller).to receive(:current_ability).and_return(@ability)
      end

      it 'should have a slug field' do
        render
        expect(rendered).to have_xpath("//input[@name='content_package[slug]']")
      end
    end
  end
end
