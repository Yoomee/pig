require "rails_helper"

module Pig
  RSpec.describe Admin::ContentPackagesController, type: :routing do
    routes { Pig::Engine.routes }
    describe "routing" do

      it "routes to #index" do
        expect(:get => "/admin/content_packages").to route_to("pig/admin/content_packages#index")
      end

      it "routes to #new" do
        expect(:get => "/admin/content_packages/new").to route_to("pig/admin/content_packages#new")
      end

      it "routes to #show" do
        cp = FactoryGirl.create(:content_package)
        expect(:get => cp.permalink.full_path).to route_to("pig/front/content_packages#show", :path => cp.permalink.full_path.gsub(/^\//, ''))
      end

      it "routes to #edit" do
        expect(:get => "/admin/content_packages/1/edit").to route_to("pig/admin/content_packages#edit", :id => "1")
      end

      it "routes to #create" do
        expect(:post => "/admin/content_packages").to route_to("pig/admin/content_packages#create")
      end

      it "routes to #update" do
        expect(:put => "/admin/content_packages/1").to route_to("pig/admin/content_packages#update", :id => "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/admin/content_packages/1").to route_to("pig/admin/content_packages#destroy", :id => "1")
      end

    end
  end
end
