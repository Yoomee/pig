Given(/^there (is|are) (\d+) personas?$/) do |ia,n|
  if n.to_i.zero?
    Pig::Persona.destroy_all
  end
  @personas = [].tap do |arr|
    n.to_i.times do
      arr << FactoryGirl.create(:persona)
    end
  end
  @persona = @personas.first
end

When(/^I go to the list of personas$/) do
  visit pig.personas_path
end

Then(/^I see the personas$/) do
  @personas.each do |persona|
    expect(page).to have_content(persona.name)
  end
end

When(/^I fill in the new persona form and submit$/) do
  visit pig.new_persona_path
  @persona = FactoryGirl.build(:persona)
  select(@persona_group.to_s, from: 'Group')
  fill_in('persona_name', :with => @persona.name)
  fill_in('persona_category', :with => @persona.category)
  fill_in('persona_age', :with => @persona.age)
  fill_in('persona_summary', :with => @persona.summary)
  click_button('Create Persona')
end

Then(/^the persona is created$/) do
  visit pig.personas_path
  expect(page).to have_content(@persona.name)
end

When(/^I choose to destroy the persona$/) do
  click_link('Delete')
end

Then(/^the persona should be destroyed$/) do
  expect{ @persona.reload }.to raise_error(ActiveRecord::RecordNotFound)
end

When(/^I edit the content package$/) do
  visit pig.edit_content_package_path(@content_package)
end

When(/^I select the persona on the form$/) do
  find(:xpath, "//input[@name='content_package[persona_ids][]' and @value='#{@persona.id}']").set(true)
  click_button('Save and continue editing')
end

Then(/^the persona should be applied to the content package$/) do
  expect(@content_package.reload.persona_ids).to include(@persona.id)
end

Given(/^there is (\d+) content package using this persona$/) do |count|
  @content_packages = []
  count.to_i.times do
    @content_packages << FactoryGirl.create(:content_package, personas: [@persona], author: @current_user)
  end
  @content_package = @content_packages.first
end

Then(/^I should see the persona$/) do
  within '.cms-sidebar' do
    click_link 'Personas'
    expect(page).to have_text(@persona.name)
  end
end

Then(/^I should see a link to find out more about the persona$/) do
  within '.cms-sidebar' do
    click_link 'Personas'
    expect(page).to have_xpath("//h4[contains(.,'#{@persona.name}')]/following-sibling::div")
  end
end

When(/^I edit the persona$/) do
  visit(pig.edit_persona_path(@persona))
end

When(/^I update the persona form and submit$/) do
  visit pig.edit_persona_path(@persona)
  fill_in 'Persona name', with: 'Foo'
  click_button 'Update Persona'
end

Then(/^the persona should be updated$/) do
  expect(@persona.reload.name).to eq('Foo')
end
