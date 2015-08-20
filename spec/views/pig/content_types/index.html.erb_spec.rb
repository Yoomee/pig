require 'rails_helper'

RSpec.describe 'pig/admin/content_types/index', type: :view do
  let(:admin) { FactoryGirl.create(:user, :admin) }
  let(:content_type_1) { FactoryGirl.create(:content_type, name: 'Foo') }
  let(:content_type_2) { FactoryGirl.create(:content_type, name: 'Bar') }

  before(:each) do
    assign(:content_types, [
      content_type_1,
      content_type_2
    ])
    allow(view).to receive(:current_user).and_return(admin)
    @ability = Pig::Ability.new(admin)
    allow(controller).to receive(:current_ability).and_return(@ability)
    render
  end

  it 'renders a list of content_types' do
    expect(rendered).to have_text('Foo')
    expect(rendered).to have_text('Bar')
  end
end
