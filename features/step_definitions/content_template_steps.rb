When(/^I destroy the content type$/) do
  visit pig.admin_content_types_path
  @deleted_content_type_id = @content_type.id
  within "tr#content-type-#{@content_type.id}" do
    click_link 'More'
    click_link 'Delete this content template'
  end
end

Then(/^the content type is destroyed$/) do
  expect(page).to have_content("The content template was successfully deleted")
  expect(page).to have_no_selector("tr#content-type-#{@deleted_content_type_id}")
end

Then(/^I can see the content template it is using$/) do
  content_type = @content_package.content_type
  expect(page).to have_link(
    content_type.name,
    href: pig.edit_admin_content_type_path(content_type)
  )
end

Then(/^the content package is created with the correct type$/) do
  expect(@content_package.content_type).to eq(@content_type)
end

When(/^I choose to add new content package from the content template$/) do
  within "tr#content-type-#{@content_type.id}" do
    click_link 'More'
    click_link 'Add new content of this type'
  end
end

Then(/^a new content package is built with this type$/) do
  expect(page).to have_select('Select a template', selected: @content_type.name)
end

When(/^I go to create a new content package$/) do
  pending # express the regexp above with the code you wish you had
end

When(/^choose the content template from a list$/) do
  pending # express the regexp above with the code you wish you had
end

When(/^fill in the content package form$/) do
  pending # express the regexp above with the code you wish you had
end

Then(/^the content package is created$/) do
  pending # express the regexp above with the code you wish you had
end
