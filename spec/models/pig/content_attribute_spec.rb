require 'rails_helper'

module Pig
  RSpec.describe ContentAttribute do
    let(:content_attribute) do
      FactoryGirl.build(:content_attribute, slug: 'banana', name: 'Banana')
    end

    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:field_type) }

    it 'is valid' do
      expect(content_attribute.valid?).to be_truthy
    end

    describe 'slug' do
      it 'cannot be equal to json_content' do
        content_attribute.slug = 'json_content'
        expect(content_attribute).to_not be_valid
      end

      it 'is set after validation' do
        content_attribute.slug = nil
        content_attribute.name = 'Apple'
        content_attribute.valid?
        expect(content_attribute.slug).to eq('apple')
      end

      it 'cannot conflict with existing method' do
        content_attribute.slug = nil
        content_attribute.name = 'Save'
        content_attribute.valid?
        expect(content_attribute.slug).to_not eq('save')
      end
    end
  end
end
