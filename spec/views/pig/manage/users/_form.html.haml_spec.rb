require 'rails_helper'

RSpec.describe 'pig/admin/manage/users/_form', type: :view do
  let(:user) { FactoryGirl.create(:user, :author) }
  before(:each) do
    assign(:user, user)
    allow(view).to receive(:current_user).and_return(user)
    ability = Pig::Ability.new(user)
    allow(controller).to receive(:current_ability).and_return(ability)
    render
  end

  it "should have a password field" do
    expect(rendered).to have_xpath("//input[@name='user[password]']")
  end

  it "should have a password confirmation field" do
    expect(rendered).to have_xpath("//input[@name='user[password_confirmation]']")
  end
end
