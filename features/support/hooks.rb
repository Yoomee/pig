Before('@admin') do
  user = FactoryGirl.create(:user, role: 'admin')
  Pig::ApplicationController.any_instance.stub(:current_user).and_return(user)
  @current_user = user
end

Before('@editor') do
  user = FactoryGirl.create(:user, role: 'admin')
  Pig::ApplicationController.any_instance.stub(:current_user).and_return(user)
  @current_user = user
end

Before('@author') do
  user = FactoryGirl.create(:user, role: 'author')
  Pig::ApplicationController.any_instance.stub(:current_user).and_return(user)
  @current_user = user
end

Before('@non-nested') do
  Pig.configuration.nested_permalinks = false
end

Before('@nested') do
  Pig.configuration.nested_permalinks = true
end

After do |scenario|
  # save_and_open_page if scenario.failed?
end