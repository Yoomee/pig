require 'rails_helper'

RSpec.describe "pig/admin/content_types/dashboard", type: :view do
  let(:admin) { FactoryGirl.create(:user, :admin) }

  before(:each) do
    @ability = Pig::Ability.new(admin)
    allow(controller).to receive(:current_ability).and_return(@ability)
    allow(view).to receive(:current_user).and_return(admin)
  end

  it "renders the recent activity" do
    user = FactoryGirl.create(:user)
    content_package = FactoryGirl.create(:content_package, editing_user: user)
    assign(:activity_items, content_package.activity_items.all )
    render
    expect(rendered).to have_text("#{content_package.name} was created by #{user.full_name}")
  end

  it "renders the number of draft content packages" do
    draft_cp = FactoryGirl.create(:content_package, status: 'draft')
    assign(:content_packages, draft_cp)
    assign(:activity_items, draft_cp.activity_items.all )
    render
    expect(rendered).to have_text('1 Draft')
  end

  it "renders the number of ready to review content packages" do
    ready_to_review_cp = FactoryGirl.create(:content_package, status: 'pending')
    assign(:content_packages, ready_to_review_cp)
    assign(:activity_items, ready_to_review_cp.activity_items.all )
    render
    expect(rendered).to have_text('1 Ready to review')
  end

  it "renders the number of getting old content packages" do
    getting_old_cp = FactoryGirl.create(:content_package)
    getting_old_cp.next_review = Date.today - 5.days
    getting_old_cp.save
    assign(:content_packages, getting_old_cp)
    assign(:activity_items, getting_old_cp.activity_items.all )
    render
    expect(rendered).to have_text('1 Getting old')
  end
end
