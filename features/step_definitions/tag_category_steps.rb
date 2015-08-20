Given(/^there (?:is|are) (\d+) tag (?:category|categories)$/) do |count|
  @tag_categories = []
  count.to_i.times do
    @tag_categories << FactoryGirl.create(:tag_category, :with_tags)
  end
  @tag_category = @tag_categories.first
end

When(/^I fill in the new tag category form and submit$/) do
  visit pig.admin_tag_categories_path
  click_link 'New Tag Category'
  fill_in 'Name', with: 'Foo'
  fill_in 'Unique identifier', with: 'foo'
  select2input = find('.select2-search__field')

  select2input.set('banana')
  within ".select2-results__options" do
    find("li", text: 'banana').click
  end

  click_button 'Save'
end

Then(/^the tag category is created$/) do
  expect(page).to have_text('Foo')
  expect(Pig::TagCategory.where(name: 'Foo').count).to eq(1)
  expect(ActsAsTaggableOn::Tag.where(name: 'banana').count).to eq(1)
end

When(/^I update the tag category's form and submit$/) do
  visit pig.admin_tag_categories_path
  click_link @tag_category.name
  fill_in 'Name', with: 'New Foo'
  fill_in 'Unique identifier', with: 'new-foo'

  @tag_to_remove = @tag_category.taxonomy_list.first
  within('.select2-selection__rendered') do
    within('li', text: @tag_to_remove) do
      find('span.select2-selection__choice__remove').click
    end
  end
  # dismiss the select2 list hiding the save button
  find('body').native.send_key(:Escape)

  click_button 'Save'
end

Then(/^the tag category should be updated$/) do
  @tag_category.reload
  expect(@tag_category.name).to eq('New Foo')
  expect(@tag_category.slug).to eq('new-foo')
  expect(@tag_category.taxonomy_list).to_not include(@tag_to_remove)
end

When(/^I assign the tag category to a content type$/) do
  @content_type = FactoryGirl.create(:content_type)
  visit pig.edit_admin_content_type_path(@content_type)
  find(:xpath, "//input[@name='content_type[tag_category_ids][]' and @value='#{@tag_category.id}']").set(true)
  click_button('Update Content type')
end

Then(/^the tag is available when creating an instance of the content type$/) do
  @content_package = FactoryGirl.create(:content_package, content_type: @content_type)
  visit(pig.edit_admin_content_package_path(@content_package))
  click_link('Tags')
  expect(page).to have_text(@tag_category.name)
end

Given(/^there is (\d+) content type with a tag category$/) do |count|
  @tag_category = FactoryGirl.create(:tag_category, :with_tags)
  @content_types = []
  count.to_i.times do
    @content_types <<
      FactoryGirl.create(:content_type, tag_category_ids: [@tag_category.id])
  end
  @content_type = @content_types.first
end

When(/^I create a content package and tag it$/) do
  @content_package = FactoryGirl.create(:content_package, content_type: @content_type, author: @current_user)
  visit(pig.edit_admin_content_package_path(@content_package))
  click_link('Tags')
  click_button(@tag_category.name)
  @tag = @tag_category.taxonomy_list.first
  find(:xpath, "//input[@name='content_package[taxonomy_tags][#{@tag_category.slug}][]' and @value='#{@tag}']").set(true)
  click_button('Save and continue editing')
end

Then(/^the content package is created with the tag$/) do
  expect(@content_package.reload.taxonomy.collect(&:name)).to include(@tag)
  visit(pig.edit_admin_content_package_path(@content_package))
  click_link('Tags')
  click_button(@tag_category.name)
  tag_input = find(:xpath, "//input[@name='content_package[taxonomy_tags][#{@tag_category.slug}][]' and @value='#{@tag}']")
  expect(tag_input.checked?).to be_truthy
end
