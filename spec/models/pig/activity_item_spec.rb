require 'rails_helper'

module Pig
  RSpec.describe ActivityItem, type: :model do

    it { should belong_to(:user) }
    it { should belong_to(:resource) }
    it { should belong_to(:parent_resource) }

    it { should validate_presence_of :user }
    
    describe 'default scope' do
      let!(:content_package_1) { FactoryGirl.create(:content_package) }
      let!(:content_package_2) { FactoryGirl.create(:content_package) }

      it 'orders by created_at descending' do
        expect(ActivityItem.all).to eq [content_package_2.activity_items.first, content_package_1.activity_items.first]
      end
    end

  end
end
