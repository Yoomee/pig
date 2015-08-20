require "rails_helper"

module Pig
  RSpec.describe Admin::TagCategoriesController, type: :routing do
    routes { Pig::Engine.routes }

    describe "routing" do
      it "routes to #index" do
        expect(:get => "/admin/tags").to route_to("pig/admin/tag_categories#index")
      end

      it "routes to #new" do
        expect(:get => "/admin/tags/new").to route_to("pig/admin/tag_categories#new")
      end

      it "routes to #edit" do
        expect(:get => "/admin/tags/1/edit").to route_to("pig/admin/tag_categories#edit", :id => "1")
      end

      it "routes to #create" do
        expect(:post => "/admin/tags").to route_to("pig/admin/tag_categories#create")
      end

      it "routes to #update" do
        expect(:put => "/admin/tags/1").to route_to("pig/admin/tag_categories#update", :id => "1")
      end
    end
  end
end
