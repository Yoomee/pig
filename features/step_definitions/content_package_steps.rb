Given(/^there (?:is|are) (\d+)\s?(draft|published)?( unpublished)?( archived)? content packages?( not\s)?(?: assigned to me)?(?: assigned to no one)?( of this type)?$/) do |n, status, unpublished, archived, assigned, using_type|
  if n.to_i.zero?
    Pig::ContentPackage.destroy_all
  end
  @content_packages = [].tap do |arr|
    n.to_i.times do |i|
      if assigned.try(:strip) == 'not'
        attrs = { title: "Content package #{i}" }
      elsif unpublished.present?
        attrs = { title: "Content package #{i}", status: 'draft' }
      else
        attrs = { title: "Content package #{i}", author: @current_user }
      end

      attrs[:status] = status if status.present?
      attrs[:content_type] = @content_type if using_type
      attrs[:archived_at] = DateTime.now if archived
      attrs[:editing_user] = @current_user || FactoryGirl.create(:user)
      arr << FactoryGirl.create(:content_package, attrs)
    end
  end
  @admin = FactoryGirl.create(:user, :admin)
  @author = FactoryGirl.create(:user, :author)
  @content_package = @content_packages.first
end

Given(/^there is 1 nested content package$/) do
  @content_package = FactoryGirl.create(:nested_content_package)
end

Given(/^there is (\d+) content package with comments$/) do |arg1|
  @content_package = FactoryGirl.create(:content_package_with_comments)
end

Given(/^there is a content package with a parent$/) do
  @parent_content_package = FactoryGirl.create(:content_package)
  @content_package = FactoryGirl.create(:content_package, :parent_id => @parent_content_package.id)
end

Given(/^there is a content package with (\d+) children$/) do |children_count|
  @content_package = FactoryGirl.create(:content_package)
  children_count.to_i.times do
    FactoryGirl.create(:content_package, parent_id: @content_package.id)
  end
end

Given(/^(?:there is|I create) a content package with the permalink path "(.*?)"$/) do |permalink|
  FactoryGirl.create(:content_package, :permalink_path => permalink)
end

Given(/^there is a content package with an inactive permalink$/) do
  @content_package = FactoryGirl.create(:content_package)
  @inactive_permalink = @content_package.permalinks.create(path: 'test-inactive-permalink', active: false, full_path: '/test-inactive-permalink')
end

When(/^I go to the sitemap$/) do
  visit pig.admin_content_packages_path
end

When(/^it changes parent$/) do
  parent_content_package = FactoryGirl.create(:content_package)
  @inactive_permalink = @content_package.permalink
  @content_package.update(:parent_id => parent_content_package.id)
end

Then(/^I see the content packages$/) do
  @content_packages.each do |content_package|
    expect(page).to have_content(content_package.to_s)
  end
end

Then(/^I can't edit the content packages$/) do
  page.all('tr.content-package').each do |tr|
    expect(tr.text).to_not have_content("Edit")
  end
end

Then(/^I can edit the content packages$/) do
  page.all('tr.content-package').each do |tr|
    expect(tr.text).to have_content("Edit")
  end
end

When(/^I fill in the new content package form and submit$/) do
  visit pig.new_admin_content_type_content_package_path(@content_type)
  @content_package = FactoryGirl.build(:content_package, :content_type => @content_type, :author => @current_user)
  select(@content_type)
  fill_in('Name', :with => @content_package.name)
  fill_in('Review date', :with => Date.today + 6.months)
  select(@content_package.author.full_name, :from => 'Author')
  click_button("Save and add content")
end

Then(/^I am taken to edit the content package$/) do
  @content_package.content_attributes.each do |content_attribute|
    expect(page).to have_content(content_attribute.name)
  end
end

When(/^I update the content package$/) do
  visit pig.edit_admin_content_package_path(@content_package)
  fill_in('Title', :with => 'Modified title')
  select(Pig::User.first.full_name, :from => 'Person')
  attach_file('Photo', File.join(Rails.root, 'public/dragonfly/defaults/user.jpg'))
  attach_file('Document', File.join(Rails.root, 'public/dragonfly/defaults/user.jpg'))
  check('Is this special?')
  click_button("Save and continue editing")
end

Then(/^the content package should change$/) do
  visit pig.edit_admin_content_package_path(@content_package)
  expect(page).to have_xpath("//img[contains(@src, \"media\")]")
  expect(find('#content_package_special')).to be_checked
  expect(find_field('Title').value).to eq('Modified title')
  expect(find_field('Person').value).to eq(Pig::User.first.id.to_s)
end

Given(/^I remove an image$/) do
  visit pig.edit_admin_content_package_path(@content_package)
  check 'content_package_remove_photo'
  click_button("Save")
end

Then(/^the image should be removed$/) do
  expect(page).to_not have_xpath("//img[contains(@src, \"media\")]")
end

When(/^I go to the content package$/) do
  visit pig.content_package_path(@content_package)
end

Then(/^I should see all its content$/) do
  @content_package.send(:content_chunk_names).each do |name|
    expect(page).to have_content(@content_package.send(name))
  end
end

When(/^I mark the content package as ready to review$/) do
  visit pig.edit_admin_content_package_path(@content_package)
  click_button("Mark as ready to review")
end

Then(/^it is assigned back to the requester$/) do
  @content_package.reload
  expect(@content_package.author_id).to eq(nil)
  assign_email = ActionMailer::Base.deliveries.last
  expect(assign_email.to).to include(@content_package.requested_by.email)
  expect(assign_email.subject).to have_content(@content_package.name)
end

When(/^I assign it to an author$/) do
  visit pig.edit_admin_content_package_path(@content_package)
  select("#{@author.full_name} (#{@author.role})", :from => 'content_package[author_id]', :visible => false)
  click_button("Save and continue editing")
end

Then(/^the content package author should change$/) do
  @content_package.reload
  expect(@content_package.author_id).to eq(@author.id)
end

Then(/^the author should be emailed$/) do
  email = ActionMailer::Base.deliveries.last
  expect(email.to).to include(@author.email)
  expect(email.subject).to have_content(@content_package.name)
end

When(/^I go to edit the content package$/) do
  visit pig.edit_admin_content_package_path(@content_package)
end

When(/^I fill in a content attribute with a (character|word) limit$/) do |word_character|
  word = word_character == 'word'
  visit pig.edit_admin_content_package_path(@content_package)
  fill_in("content_package_#{word ? 'text' : 'title'}", :with => (word ? "a " : "a") * 10, :visible => false)
end

Then(/^the (character|word) counter should increase$/) do |word_character|
  expect(page).to have_content("10/30")
end

When(/^I exceed the (character|word) limit of a content attribute$/) do |word_character|
  word = word_character == 'word'
  visit pig.edit_admin_content_package_path(@content_package)
  fill_in("content_package_#{word ? 'text' : 'title'}", :with => (word ? "a " : "a") * 31, :visible => false)
end

Then(/^the (character|word) counter should go red$/) do |word_character|
  word = word_character == 'word'
  expect(find("#content_package_#{word ? 'text' : 'title'}_input")['class']).to include("word-count-exceeded")
end

When(/^I visit its permalink$/) do
  visit "/#{@content_package.permalink_path}".squeeze '/'
end

When(/^I change the content package "(.*?)" to "(.*?)"$/) do |attribute, value|
  @content_package.update(attribute.to_sym => value)
end

Then(/^I should get redirected to its permalink$/) do
  expect(current_path).to eq("/#{@content_package.permalink.full_path}".squeeze '/')
end

When(/^I visit its full path permalink$/) do
  visit @content_package.permalink.full_path
end

When(/^I visit the inactive permalink$/) do
  visit @inactive_permalink.full_path
end

When(/^I visit the inactive permalink with params$/) do
  @params = 'utm_campaign=STA'
  visit @inactive_permalink.full_path + '?' + @params
end

Then(/^I should get an error$/) do
  pending # express the regexp above with the code you wish you had
end

Then(/^I should get redirected to the login page$/) do
  expect(current_path).to eq(pig.new_user_session_path)
end

Then(/^I should see the params$/) do
  expect(URI.parse(current_url).query).to eq(@params)
end

Given(/^one of the content packages is named "(.*?)"$/) do |name|
  cp = Pig::ContentPackage.first
  cp.editing_user = @current_user
  cp.update_attribute(:name, name)
end

When(/^I go to the list of content packages$/) do
  visit pig.admin_content_packages_path
end

When(/^I search for "(.*?)"$/) do |term|
  search_field = find('#content_search_link')
  search_field.set term
  # We need to press down here to trigger the ajax call, just setting with capybara doesn't trigger autocomplete
  search_field.native.send_keys(:Down)
  wait_for_ajax
  search_field.native.send_keys(:Down, :Return)
  wait_for_ajax
end

Then(/^I should see the content package named "(.*?)" highlighted$/) do |name|
  content_package = Pig::ContentPackage.where(name: name).first
  row = page.find("tr[id=content-package-#{content_package.id}]")
  row[:class].include?('.highlight')
end

When(/^I expand the parent$/) do
  find(".td-name").click
end

Then(/^the (\d+) children are visible$/) do |children_count|
  expect(page).to have_css(".td-name", count: children_count.to_i + 1) # + 1 for parent
end


When(/^the content package is archived$/) do
  @content_package.slug = ''
  @content_package.archive
end

When(/^the content package is destroyed$/) do
  @content_package.destroy
end

When(/^the content package is restored$/) do
  @content_package.restore
end

Given(/^the content package has recent activity$/) do
  for i in 1..5 do
    @content_package.record_activity!(@current_user, "updated")
  end
end

Then(/^I should see the recent activity$/) do
  expect(first(".cms-activity-feed li")).to have_text("#{@content_package.name} was updated by #{@content_package.author.full_name}")
end

Then(/^I should see more activity$/) do
  expect(all(".cms-activity-feed li").count).to eq(6)
end

When(/^the content package is updated$/) do
  @content_package.update_attribute(:name, 'New name')
end

Then(/^I see the content packages in the open requests area$/) do
  pending # express the regexp above with the code you wish you had
end

When(/^I publish the content package$/) do
  visit pig.edit_admin_content_package_path(@content_package)
  select('Published', from: 'Status')
  click_button('Save and continue editing')
end

Then(/^the content package should be published$/) do
  @content_package.reload
  expect(@content_package.status).to eq("published")
end

When(/^I archive the content package$/) do
  @content_package.slug = ''
  @content_package.save
  visit pig.admin_content_packages_path
  within "tr#content-package-#{@content_package.id}" do
    click_link 'More'
    click_link 'Archive'
  end
end

When(/^I destroy the content package$/) do
  @archived_content_package_id = @content_package.id
  visit pig.archived_admin_content_packages_path
  within "tr#archived-content-package-#{@content_package.id}" do
    click_link 'Destroy'
  end
end

When(/^I try go to the archived content package$/) do
  visit pig.content_package_path(@archived_content_package_id)
end

Then(/^It should no longer be visible in the sitemap$/) do
  expect(page).to have_no_selector("tr#content-package-#{@content_package.id}")
end

Then(/^it should appear in the list of archived content packages$/) do
  visit pig.archived_admin_content_packages_path
  expect(page).to have_content(@content_package.name)
end

When(/^I restore the content package$/) do
  visit pig.archived_admin_content_packages_path
  within "tr#archived-content-package-#{@content_package.id}" do
    click_link 'Restore'
  end
end

Then(/^it should appear in the sitemap$/) do
  visit pig.admin_content_packages_path
  expect(page).to have_selector("tr#content-package-#{@content_package.id}")
end

Then(/^It shouldn't appear in the list of archived content packages$/) do
  visit pig.archived_admin_content_packages_path
  expect(page).to have_no_selector("tr#archived-content-package-#{@content_package.id}")
end

When(/^I add a child to the content package$/) do
  visit pig.admin_content_packages_path
  within "tr#content-package-#{@content_package.id}" do
    click_link 'More'
    click_link 'Add child'
  end
end

When(/^I fill in the new child content package form and submit$/) do
  content_type = Pig::ContentType.first
  content_package = FactoryGirl.build(:content_package, :content_type => content_type, :author => @admin)
  find('#content_package_content_type_input .custom-combobox-toggle').click
  find('li.ui-menu-item', text: content_type.name).click
  fill_in('Name', :with => content_package.name)
  click_button "Assign author"
  select(content_package.author.full_name, :from => 'Author')
  click_button("Save and add content")
  @child_content_package = Pig::ContentPackage.last
end

Then(/^the content package should appear as a child in the sitemap$/) do
  visit pig.admin_content_packages_path
  wait_for_ajax
  find("tr#content-package-#{@content_package.id} td:first-of-type").click
  wait_for_ajax
  expect(page).to have_selector("tr#content-package-#{@child_content_package.id}")
end

When(/^I move the child to a new parent$/) do
  visit pig.edit_admin_content_package_path(@content_package)
  click_link "Settings"
  select(@parent_content_package.name, from: "Parent")
  click_button('Save and continue editing')
end

Then(/^the content package should move to the new parent$/) do
  @content_package.parent = @parent_content_package
end

When(/^I mark the content package as published$/) do
  visit pig.edit_admin_content_package_path(@content_package)
  select('Published', from: "Status")
end

When(/^I visit the content package edit page$/) do
  visit pig.edit_admin_content_package_path(@content_package)
end

When(/^I click "(.*?)"$/) do |text|
  click_button text
end

Then(/^I should be on the content package edit page$/) do
  expect(page.current_path).
    to eq(pig.edit_admin_content_package_path(@content_package))
end

Then(/^I should be on the content package show page$/) do
  expect(page.current_path).
    to eq(pig.content_package_path(@content_package))
end

When(/^I reorder the children$/) do
  visit pig.reorder_admin_content_package_path(@content_package)
  first = find('#children_ids_2')
  second = find('#children_ids_3')
  first.drag_to(second)
  click_link('Save order')
end

Then(/^the children are reordered$/) do
  expect(@content_package.children.pluck(:id)).to eq([3,2,4])
end

When(/^the content package is edited$/) do
  @old_title = @content_package.title
  @content_package.title = "New Title"
  @content_package.status = "update"
  @content_package.save
end

Then(/^I see the original content package$/) do
  expect(page).to have_content @old_title
  expect(page).to_not have_content "New Title"
end

When(/^I change the assigned to field to an author$/) do
  visit pig.edit_admin_content_package_path(@content_package)
  select("#{@author.full_name} (#{@author.role})", :from => 'content_package[author_id]', :visible => false)
end

Then(/^status is changed to Update$/) do
  expect(page).to have_select('Status', selected: 'Needs updating')
end

When(/^I visit the content packages preview url$/) do
  visit pig.preview_admin_content_package_path(@content_package)
end

Then(/^I see the updated content package$/) do
  expect(page).to have_content "New Title"
  expect(page).to_not have_content @old_title
end

Then(/^I can still view the old content package$/) do
  visit pig.preview_admin_content_package_path(@content_package)
  expect(page).to have_content(@content_package.title)
end
