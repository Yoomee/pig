FactoryGirl.define do

  factory :content_type, class: Pig::ContentType do
    sequence(:name) { |n| "Content type #{n}" }
    description "Share your latest news"
    singleton false
    view_name 'show'
    use_workflow true
    after(:build) do |content_type|
      if content_type.content_attributes.count.zero?
        content_type.content_attributes = [
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'title', :limit_unit => 'character', :limit_quantity => 30),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'text', :name => 'Text', :field_type => 'text', :description => 'Tell a story', :limit_unit => 'word', :limit_quantity => 30),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'photo', :name => 'Photo', :field_type => 'image', :description => 'Add a picture'),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'document', :name => 'Document', :field_type => 'file', :description => 'Add a file'),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'video', :name => 'Video', :field_type => 'embeddable', :description => 'Add a video'),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'link', :name => 'Link', :field_type => 'link', :description => 'Add a link'),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'special', :name => 'Is this special?', :field_type => 'boolean', :description => 'Yes or no'),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'skills', :name => 'Skills', :field_type => 'tags', :description => 'list some skills'),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'person', :name => 'Person', :field_type => 'user', :description => 'Choose someone'),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'date', :name => 'Date', :field_type => 'date', :description => 'Pick a date'),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'time', :name => 'Time', :field_type => 'time', :description => 'Pick a time'),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'geo', :name => 'Location', :field_type => 'location', :description => 'Pick a location'),
          FactoryGirl.build(:content_attribute, :content_type => content_type, :slug => 'rich_content', :name => 'Rich Content', :field_type => 'rich_content', :description => 'Enter some rich content')
        ]
      end
    end

    trait :viewless do
      viewless true
    end
  end

  factory :content_attribute, class: Pig::ContentAttribute do
    content_type
    slug "title"
    name "Title"
    description "Choose a pithy title"
    field_type 'string'
    sequence(:position)
  end

  factory :user, aliases: [:author, :requested_by], class: Pig::User  do
    first_name "Charles"
    sequence(:last_name) {|n| "Barrett #{n}"}
    sequence(:email) {|n| "charles@barrett-#{n}.com"}
    password "password"
    role "admin"
    bio "I am an original bio"
    confirmed_at DateTime.now

    trait :unconfirmed do
      after(:create) { |user| user.update_attribute(:confirmed_at, nil) }
    end
    trait :author do
      before(:create) { |user| user.role = "author" }
    end
    trait :admin do
      after(:create) {|user| user.role = "admin" }
    end
    trait :developer do
      after(:create) {|user| user.role = "developer" }
    end
    trait :editor do
      after(:create) {|user| user.role = "editor" }
    end
    trait :author do
      after(:create) {|user| user.role = "author" }
    end
  end

  factory :activity_item, class: Pig::ActivityItem do
    user
  end

  factory :permalink, class: Pig::Permalink do
    sequence(:path) { |n| "foo-#{n}" }
    sequence(:full_path) { |n| "/foo-#{n}" }
    active false
  end

  factory :comment, class: Pig::Comment do
    sequence(:title) {|n| "Comment title #{n}"}
    sequence(:comment) {|n| "Comment message #{n}"}
    user
  end

  factory :content_package, class: Pig::ContentPackage do
    sequence(:name) {|n| "Content package #{n}"}
    content_type
    next_review Date.today + 6.months
    due_date Date.today + 6.months
    author
    requested_by
    sequence(:permalink_path) {|n| "my-nice-permalink-#{n}"}
    status "published"
    publish_at Date.today - 1.day
    sequence(:slug){|n| "content_package_#{n}" }
    editing_user { FactoryGirl.create(:user) }

    factory :nested_content_package do
      association :parent, factory: :content_package
    end

    factory :viewless_content_package do
      association :content_type, :viewless
    end

    factory :content_package_with_comments do
      transient do
        comments_count 3
      end

      after(:create) do |cp, evaluator|
        create_list(:comment, evaluator.comments_count, commentable: cp)
      end
    end

  end

  factory :persona_group, class: Pig::PersonaGroup, :aliases => [:group] do
    sequence(:name) { |n| "Persona group #{n}" }
  end

  factory :persona, class: Pig::Persona do
    group
    sequence(:name){|n| "Bob Smith #{n}" }
    category "Persona category"
    age 18
    summary "Persona summary"
    benefit_1 "Benefit 1"
    benefit_2 "Benefit 2"
    benefit_3 "Benefit 3"
    benefit_4 "Benefit 4"
  end

  factory :meta_datum, class: Pig::MetaDatum, :aliases => [:meta_data] do
    page_slug 'page_slug'
    sequence(:title) { |n| "Meta title #{n}" }
    sequence(:description) { |n| "Meta description #{n}" }
    sequence(:keywords) { |n| "Meta keywords #{n}" }
  end

  factory :tag_category, class: Pig::TagCategory do
    sequence(:name) {|n| "Tag category name #{n}" }
    sequence(:slug) {|n| "Tag category slug #{n}" }

    trait(:with_tags) do
      taxonomy_list 'Foo, Bar'
    end
  end

  factory :tag, class: ActsAsTaggableOn::Tag do
    sequence(:name) {|n| "Tag #{n}" }
  end

end
