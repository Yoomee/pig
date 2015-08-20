require 'rails_helper'

module Pig
  RSpec.describe Admin::ContentTypesController, type: :controller do
    routes { Pig::Engine.routes }

    # This should return the minimal set of attributes required to create a valid
    # ContentType. As you add validations to ContentType, be sure to
    # adjust the attributes here as well.
    let(:valid_attributes) {
      FactoryGirl.attributes_for(:content_type)
    }

    let(:invalid_attributes) {
      { name: '' }
    }

    # This should return the minimal set of values that should be in the session
    # in order to pass any filters (e.g. authentication) defined in
    # ContentTypesController. Be sure to keep this updated too.
    let(:valid_session) { {} }

    context "signed in" do
      login_admin

      describe "GET #index" do
        it "assigns all content_types as @content_types" do
          content_type = Pig::ContentType.create! valid_attributes
          get :index, {}, valid_session
          expect(assigns(:content_types)).to eq([content_type])
        end
      end

      describe "GET #new" do
        it "assigns a new content_type as @content_type" do
          get :new, {}, valid_session
          expect(assigns(:content_type)).to be_a_new(Pig::ContentType)
        end
      end

      describe "GET #edit" do
        it "assigns the requested content_type as @content_type" do
          content_type = Pig::ContentType.create! valid_attributes
          get :edit, {:id => content_type.to_param}, valid_session
          expect(assigns(:content_type)).to eq(content_type)
        end
      end

      describe "POST #create" do
        context "with valid params" do
          it "creates a new ContentType" do
            expect {
              post :create, {:content_type => valid_attributes}, valid_session
            }.to change(Pig::ContentType, :count).by(1)
          end

          it "assigns a newly created content_type as @content_type" do
            post :create, {:content_type => valid_attributes}, valid_session
            expect(assigns(:content_type)).to be_a(Pig::ContentType)
            expect(assigns(:content_type)).to be_persisted
          end

          it "redirects to the created content_type" do
            post :create, {:content_type => valid_attributes}, valid_session
            expect(response).to redirect_to(admin_content_types_path)
          end
        end

        context "with invalid params" do
          it "assigns a newly created but unsaved content_type as @content_type" do
            post :create, {:content_type => invalid_attributes}, valid_session
            expect(assigns(:content_type)).to be_a_new(Pig::ContentType)
          end

          it "re-renders the 'new' template" do
            post :create, {:content_type => invalid_attributes}, valid_session
            expect(response).to render_template("new")
          end
        end
      end

      describe "PUT #update" do
        context "with valid params" do
          let(:new_attributes) {
            {name: "New name"}
          }

          it "updates the requested content_type" do
            content_type = Pig::ContentType.create! valid_attributes
            put :update, {:id => content_type.to_param, :content_type => new_attributes}, valid_session
            content_type.reload
            expect(assigns(:content_type).name).to eq('New name')
          end

          it "assigns the requested content_type as @content_type" do
            content_type = Pig::ContentType.create! valid_attributes
            put :update, {:id => content_type.to_param, :content_type => valid_attributes}, valid_session
            expect(assigns(:content_type)).to eq(content_type)
          end

          it "redirects to the content_type" do
            content_type = Pig::ContentType.create! valid_attributes
            put :update, {:id => content_type.to_param, :content_type => valid_attributes}, valid_session
            expect(response).to redirect_to(admin_content_types_path)
          end
        end

        context "with invalid params" do
          it "assigns the content_type as @content_type" do
            content_type = Pig::ContentType.create! valid_attributes
            put :update, {:id => content_type.to_param, :content_type => invalid_attributes}, valid_session
            expect(assigns(:content_type)).to eq(content_type)
          end

          it "re-renders the 'edit' template" do
            content_type = Pig::ContentType.create! valid_attributes
            put :update, {:id => content_type.to_param, :content_type => invalid_attributes}, valid_session
            expect(response).to render_template("edit")
          end
        end
      end

      describe "DELETE #destroy" do
        it "destroys the requested content_type" do
          content_type = Pig::ContentType.create! valid_attributes
          expect {
            delete :destroy, {:id => content_type.to_param}, valid_session
          }.to change(Pig::ContentType, :count).by(-1)
        end

        it "redirects to the content_types list" do
          content_type = Pig::ContentType.create! valid_attributes
          delete :destroy, {:id => content_type.to_param}, valid_session
          expect(response).to redirect_to(admin_content_types_url)
        end
      end
    end

  end
end
