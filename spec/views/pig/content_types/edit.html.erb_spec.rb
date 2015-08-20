require 'rails_helper'

RSpec.describe "pig/admin/content_types/edit", type: :view do
  let(:admin) { FactoryGirl.create(:user, :admin) }

  before(:each) do
    @content_type = assign(:content_type, FactoryGirl.create(:content_type))
    @ability = Pig::Ability.new(admin)
    allow(controller).to receive(:current_ability).and_return(@ability)
  end

  it "renders the edit content_type form" do
    render

    assert_select "form[action=?][method=?]", pig.admin_content_type_path(@content_type), "post" do
    end
  end
end
