When(/^I visit the sign in page$/) do
  visit pig.new_user_session_path
end

When(/^I complete the form with email "(.*?)" and password "(.*?)"$/) do |email, password|
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  click_button 'Log in'
end

Then(/^I should be redirected to the dashboard$/) do
  expect(current_path).to eq(pig.admin_root_path)
end

Then(/^I should be redirected to the sign in page$/) do
  expect(current_path).to eq(pig.new_user_session_path)
end

Then(/^I should see an "(.*?)" message$/) do |message|
  expect(page).to have_text(message)
end

Given(/^an author exists with email "(.*?)"(?: and password "(.*?)")?$/) do |email, password|
  params = {}
  @email = params[:email] = email if email.present?
  @password = params[:password] = password if password.present?
  FactoryGirl.create(:user, :author, params)
end

When(/^I click the forgotten password link$/) do
  click_link 'Forgot your password?'
end

When(/^I complete the forgotten password form with email "(.*?)"$/) do |email|
  fill_in 'Email', with: email
  click_button 'Send me reset password instructions'
end

Then(/^I should receive an email with password reset instructions$/) do
  open_email(@email)
  expect(current_email.subject).to eq('Reset password instructions')
end

Given(/^I have requested a password reset$/) do
  visit pig.new_user_password_path
  fill_in 'Email', with: @email
  click_button 'Send me reset password instructions'
end

When(/^I follow the reset link in the instructions$/) do
  open_email(@email)
  current_email.click_link 'Change my password'
end

When(/^I choose a new password$/) do
  fill_in 'New password', with: 'foobar123'
  fill_in 'Confirm new password', with: 'foobar123'
  click_button 'Change my password'
end
