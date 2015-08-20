Given(/^there (is|are) (\d+) content types?$/) do |ia,n|
  if n.to_i.zero?
    Pig::ContentType.destroy_all
  end
  @content_types = [].tap do |arr|
    n.to_i.times do
      arr << FactoryGirl.create(:content_type)
    end
  end
  @content_type = @content_types.first
end

When(/^I go to the list of content types$/) do
  visit pig.admin_content_types_path
end

Then(/^I see the content types$/) do
  @content_types.each do |content_type|
    expect(page).to have_content(content_type.to_s)
  end
end

When(/^I fill in the new content type form and submit$/) do
  visit pig.new_admin_content_type_path
  @content_type = FactoryGirl.build(:content_type)
  fill_in('content_type_name', :with => @content_type.name)
  @content_type.content_attributes.each_with_index do |content_attribute, idx|
    click_link('Add another content attribute') unless idx.zero?
    all(".nested-fields input[id$='_name']")[idx].set(content_attribute.name)
    all(".nested-fields textarea[id$='_description']")[idx].set(content_attribute.description)
    Capybara.ignore_hidden_elements = false
    all(".nested-fields select[id$='_field_type']")[idx].find("option[value='#{content_attribute.field_type}']").select_option
    Capybara.ignore_hidden_elements = true
  end
  click_button('Create Content type')
end

Then(/^the content type is created$/) do
  step "I go to the list of content types"
  expect(page).to have_content(@content_type.to_s)
end

When(/^I update the content type$/) do
  visit pig.edit_admin_content_type_path(@content_type)
  fill_in('content_type_name', :with => 'Modified name')
  click_button("Update Content type")
end

Then(/^the content type should change$/) do
  visit pig.edit_admin_content_type_path(@content_type)
  expect(find_field('content_type[name]').value).to eq('Modified name')
end

When(/^I duplicate the content type$/) do
  visit pig.admin_content_types_path
  within "#content-type-#{@content_type.id}" do
    click_link "More"
    click_link "Duplicate..."
  end

  within "#duplicate-modal" do
    click_button "Duplicate"
  end
end

Then(/^I see a new content type with all the same attributes$/) do
  @content_type.content_attributes.each_with_index do |content_attribute, idx|
    Pig::ContentAttribute.fields_to_duplicate.each do |attribute|
      expected_value = content_attribute.send(attribute)
      if expected_value.is_a?(TrueClass) || expected_value.is_a?(FalseClass)
        if expected_value
          expect(find_field("content_type[content_attributes_attributes][#{idx}][#{attribute}]")).to be_checked
        else
          expect(find_field("content_type[content_attributes_attributes][#{idx}][#{attribute}]")).to_not be_checked
        end
      elsif expected_value.to_s.present?
        expect(find_field("content_type[content_attributes_attributes][#{idx}][#{attribute}]").value.to_s).to eq(expected_value.to_s)
      end
    end
  end
end

When(/^I duplicate the first content type onto the second$/) do
  visit pig.duplicate_admin_content_type_path(@content_types.first, :to => @content_types.last)
end

Then(/^I see a second content type with all the attributes of the first$/) do
  seed = @content_types.first
  target = @content_types.last
  # Only check first five to speed up test
  (target.content_attributes + seed.content_attributes)[0..4].each_with_index do |content_attribute, idx|
    Pig::ContentAttribute.fields_to_duplicate.each do |attribute|
      expected_value = content_attribute.send(attribute)
      if expected_value.is_a?(TrueClass) || expected_value.is_a?(FalseClass)
        if expected_value
          expect(find_field("content_type[content_attributes_attributes][#{idx}][#{attribute}]")).to be_checked
        else
          expect(find_field("content_type[content_attributes_attributes][#{idx}][#{attribute}]")).to_not be_checked
        end
      elsif expected_value.to_s.present?
        expect(find_field("content_type[content_attributes_attributes][#{idx}][#{attribute}]").value.to_s).to eq(expected_value.to_s)
      end
    end
  end
end

When(/^I open the tree for the type$/) do
  within "#content-type-#{@content_type.id}" do
    find('.td-name').click
  end
  wait_for_ajax
end

Then(/^I should see the content package$/) do
  expect(page).to have_content(@content_package.name)
end
