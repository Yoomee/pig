require 'rails_helper'

module Pig
  RSpec.describe ContentPackage do
    let(:content_package) do
      FactoryGirl.build(:content_package)
    end
    it { should delegate_method(:viewless?).to(:content_type) }
    it { should delegate_method(:package_name).to(:content_type) }
    it { should delegate_method(:missing_view?).to(:content_type) }
    it { should delegate_method(:view_name).to(:content_type) }
    it { should delegate_method(:content_attributes).to(:content_type) }
    it { should delegate_method(:tag_categories).to(:content_type) }

    it { should validate_presence_of(:content_type) }
    it { should have_one(:permalink).conditions(active: true) }
    it { should have_many(:permalinks) }
    it { should belong_to(:parent) }
    it { should have_many(:activity_items) }

    it { should belong_to(:content_type) }
    it { should belong_to(:parent).class_name('ContentPackage') }
    it { should have_many(:content_chunks) }
    it { should have_many(:archived_children)
      .class_name('ContentPackage')
      .with_foreign_key('parent_id')
      .conditions('archived_at IS NOT NULL')
      .order([:position, :id])
    }
    it { should have_and_belong_to_many(:personas).class_name('Pig::Persona') }
    it { should belong_to(:author).class_name('Pig::User') }
    it { should belong_to(:requested_by).class_name('Pig::User') }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:requested_by) }
    it { should validate_presence_of(:next_review) }

    it 'is valid' do
      content_package.valid?
      expect(content_package.errors.full_messages).to eq([])
      expect(content_package.valid?).to be_truthy
    end

    describe 'getting attribute' do
      it 'should work for content_attribute' do
        expect{ content_package.title }.not_to raise_error
      end
      it 'should not work for other attributes' do
        expect{ content_package.title2 }.to raise_error(NoMethodError)
      end
    end

    describe 'setting attribute' do
      it 'should work for content_attribute' do
        content_package.title = "A new title"
        expect(content_package.title).to eq("A new title")
      end
      it 'should not work for other attributes' do
        expect{ content_package.title2 = "title" }.to raise_error(NoMethodError)
      end
    end

    describe 'changing attribute' do
      it 'should work for content_attribute' do
        content_package.save
        content_package.title = "A new title"
        content_package.save
        content_package.reload
        expect(content_package.title).to eq("A new title")
      end
    end

    describe 'required fields' do
      it 'should be required' do
        content_package.save
        ca = content_package.content_attributes.first
        ca.required = true
        content_package.send("#{ca.slug}=",nil)
        expect(content_package).to_not be_valid
      end
    end

    describe 'image attributes' do
      it 'can be got' do
        expect{ content_package.photo }.not_to raise_error
      end
      it 'can be got by photo_uid' do
        expect{ content_package.photo_uid }.not_to raise_error
      end
      it 'can be set' do
        expect{ content_package.photo = File.read(File.join(Rails.root, 'public/dragonfly/defaults/user.jpg')) }.not_to raise_error
      end
      it 'can generate thumbnail' do
        content_package.photo = File.read(File.join(Rails.root, 'public/dragonfly/defaults/user.jpg'))
        expect(content_package.photo.thumb('100x100#').url).to match(/^\/media\//)
      end
      it 'can be removed by calling remove_photo' do
        content_package.photo = File.read(File.join(Rails.root, 'public/dragonfly/defaults/user.jpg'))
        content_package.save
        content_package.remove_photo
        content_package.save
        expect(content_package.photo).to be_nil
      end
      it 'can be removed by setiing photo_uid to nil' do
        content_package.photo = File.read(File.join(Rails.root, 'public/dragonfly/defaults/user.jpg'))
        content_package.save
        content_package.photo_uid = nil
        content_package.save
        expect(content_package.photo).to be_nil
      end
    end

    describe 'embeddable attributes' do
      it 'can be got' do
        expect{ content_package.video }.not_to raise_error
      end
      it 'can be got via _url' do
        expect{ content_package.video_url }.not_to raise_error
      end
      it 'can be set' do
        expect{ content_package.video_url = "http://www.youtube.com/watch?v=qvmc9d0dlOg" }.not_to raise_error
      end
      it 'are invalid with bad URL ' do
        skip('Fetch HTML for embed needs webmock response setting up')
        content_package.video_url = "http://www.youtube.com/watch?v=qvmc9d0dlO"
        expect(content_package.valid?).to be_falsey
      end
      it 'fetches HTML' do
        skip('Fetch HTML for embed needs webmock response setting up')
        content_package.video_url = "http://www.youtube.com/watch?v=qvmc9d0dlO"
        content_package.valid?
        expect(content_package.video).to_not be_blank
      end
    end

    describe 'link attributes' do
      it 'can be set as a URL' do
        url = 'http://yoomee.com'
        content_package.link = url
        expect(content_package.link.value).to eq(url)
      end
      it 'can be set as a content package' do
        package_2 = FactoryGirl.create(:content_package)
        content_package.link = package_2.id
        expect(content_package.link.value).to eq(package_2)
      end
    end

    describe 'text attributes' do
      it 'defaults to empty string' do
        expect(content_package.text).to eq('')
      end
      it 'can be set' do
        content_package.text = 'Foo'
        content_package.save
        content_package.reload
        expect(content_package.text).to eq('Foo')
      end
    end

    describe 'string attributes' do
      it 'defaults to empty string' do
        expect(content_package.title).to eq('')
      end
      it 'can be set' do
        content_package.title = 'Foo'
        content_package.save
        content_package.reload
        expect(content_package.title).to eq('Foo')
      end
    end

    describe 'rich content attributes' do
      it 'defaults to empty string' do
        expect(content_package.rich_content).to eq('')
      end
      it 'can be set' do
        content_package.rich_content = '<p>Foo</p>'
        content_package.save
        content_package.reload
        expect(content_package.rich_content).to eq('<p>Foo</p>')
      end
    end

    describe 'date attributes' do
      it 'defaults to nil' do
        expect(content_package.date).to be_nil
      end
      it 'can be set' do
        content_package.date = '2015-09-23'
        content_package.save
        content_package.reload
        expect(content_package.date).to_not be_nil
      end
      it 'returns a date object' do
        content_package.date = '2015-09-23'
        content_package.save
        content_package.reload
        expect(content_package.date).to be_a(Date)
      end
    end

    describe 'time attributes' do
      it 'defaults to empty string'
      it 'can be set'
    end

    describe 'boolean attributes' do
      it 'can be got' do
        expect(content_package.special).to eq(false)
      end
      it 'can be set' do
        content_package.special = '1'
        expect(content_package.special).to eq(true)
      end
      it 'can be got with a boolean accessor' do
        expect(content_package.special?).to eq(false)
      end
    end

    describe 'tags attributes' do
      it 'can be got' do
        expect(content_package.skill_list).to eq('')
      end
      it 'can be set' do
        skills = %w(shooting hunting fishing)
        content_package.skill_list = skills.join(',')
        content_package.save
        expect(content_package.skill_list).to eq('shooting, hunting, fishing')
      end
    end

    describe 'user attributes' do
      it 'can be got' do
        expect(content_package.person).to eq(nil)
      end
      it 'can be set as a user id' do
        content_package.person_id = Pig::User.first.id
        content_package.save
        expect(content_package.person_id).to eq(Pig::User.first.id)
        expect(content_package.person).to eq(Pig::User.first)
      end
      it 'can be set as a user' do
        content_package.person = Pig::User.last
        content_package.save
        expect(content_package.person).to eq(Pig::User.last)
      end
    end

    describe 'location attributes' do
      it 'can be got' do
        expect{ content_package.geo }.not_to raise_error
      end
      it 'can be set' do
        expect{ content_package.geo = "Sheffield" }.not_to raise_error
      end
      it 'fetches latitude & longitude' do
        content_package.geo = "Sheffield"
        content_package.save
        expect(content_package.geo_lat_lng).to_not be_blank
      end
    end

    describe 'Having the correct URL' do

      it 'has a permalink if not viewless' do
        cp = FactoryGirl.create(:content_package, permalink_path: nil)
        expect(content_package.permalink_path).not_to be_blank
      end

      it "doesn't have a permalink if viewless" do
        content_package.content_type.viewless = true
        content_package.build_permalink
        content_package.permalink_path = nil
        content_package.valid?
        expect(content_package.permalink_path).to be_nil
      end

      it 'cant have a duplicate permalink' do
        content_package.permalink_path = "test"
        content_package.save
        cp = FactoryGirl.build(:content_package, :permalink_path => "test")
        expect(cp).to_not be_valid
      end

      it "updates the permalinks of all descendants when it is saved" do
        content_package.save

        # level 1
        cp_v = FactoryGirl.create(:content_package, :parent => content_package, permalink_path: 'first')
        # level 2
        cp_v_v = FactoryGirl.create(:content_package, :parent => cp_v)
        # level 3
        cp_v_v_v = FactoryGirl.create(:content_package, :parent => cp_v_v)
        cps = [content_package, cp_v, cp_v_v, cp_v_v_v]

        original_paths = []
        cps.each do |cp|
          cp.reload
          original_paths << cp.permalink_full_path
        end

        cp_v.permalink_path = 'second'
        cp_v.save

        cps.each_with_index do |cp, index|
          cp.reload
          if original_paths[index]
            original_path = original_paths[index].gsub 'first', 'second'
            expect(cp.permalink.full_path).to match(/#{original_path}/)
          else
            expect(cp.permalink.full_path).to be_nil
          end
        end
      end

    end

    describe 'Deleting' do

      it 'can be archived' do
        content_package.slug = nil
        content_package.archive
        expect(content_package.archived?).to be_truthy
      end

      it 'has its children archived too' do
        content_package.slug = nil
        content_package.save
        content_package.children << FactoryGirl.create(:content_package, :parent => content_package, :slug => nil)
        content_package.archive
        content_package.reload
        expect(content_package.children.all?(&:archived?)).to be_truthy
      end

      it 'cannot be archived if it has a slug' do
        content_package.archive
        expect(content_package.archived?).to be_falsey
      end

      it 'cannot be archived if it has a child with a slug' do
        content_package.slug = nil
        content_package.save
        content_package.children << FactoryGirl.build(:content_package, :parent => content_package)
        content_package.archive
        expect(content_package.archived?).to be_falsey
      end

    end

  end

  describe '.with_content_type_name' do
    let(:ct_1) { FactoryGirl.create(:content_type, name: 'foo') }
    let(:ct_2) { FactoryGirl.create(:content_type, name: 'bar') }
    let!(:cp_1) { FactoryGirl.create(:content_package, content_type: ct_1) }
    let!(:cp_2) { FactoryGirl.create(:content_package, content_type: ct_2) }
    it 'returns only content packages using a type with this name' do
      expect(ContentPackage.with_content_type_name('foo')).to eq([cp_1])
    end
  end
end
