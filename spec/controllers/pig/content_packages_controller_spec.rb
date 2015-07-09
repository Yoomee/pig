require 'rails_helper'

module Pig
  RSpec.describe ContentPackagesController, type: :controller do
    routes { Pig::Engine.routes }

    # This should return the minimal set of attributes required to create a valid
    # ContentPackage. As you add validations to ContentPackage, be sure to
    # adjust the attributes here as well.
    let(:valid_attributes) {
      ControllerMacros.attributes_with_foreign_keys(:content_package)
    }

    let(:invalid_attributes) {
      { name: '' }
    }

    # This should return the minimal set of values that should be in the session
    # in order to pass any filters (e.g. authentication) defined in
    # ContentPackagesController. Be sure to keep this updated too.
    let(:valid_session) { {} }

    context "signed in" do
      login_admin
      describe "GET #index" do
        it "assigns all content_packages as @content_packages" do
          content_package = ContentPackage.create! valid_attributes
          get :index, {}, valid_session
          expect(assigns(:content_packages).to_a).to eq([content_package])
        end
      end

      describe "GET #show" do
        it "assigns the requested content_package as @content_package" do
          content_package = ContentPackage.create! valid_attributes
          get :show, {:id => content_package.to_param}, valid_session
          expect(assigns(:content_package)).to eq(content_package)
        end
      end

      describe "GET #new" do
        it "assigns a new content_package as @content_package" do
          get :new, {}, valid_session
          expect(assigns(:content_package)).to be_a_new(ContentPackage)
        end
      end

      describe "GET #edit" do
        it "assigns the requested content_package as @content_package" do
          content_package = ContentPackage.create! valid_attributes
          get :edit, {:id => content_package.to_param}, valid_session
          expect(assigns(:content_package)).to eq(content_package)
        end
      end

      describe "POST #create" do
        context "with valid params" do
          it "creates a new ContentPackage" do
            expect {
              post :create, {:content_package => valid_attributes}, valid_session
            }.to change(ContentPackage, :count).by(1)
          end

          it "assigns a newly created content_package as @content_package" do
            post :create, {:content_package => valid_attributes}, valid_session
            expect(assigns(:content_package)).to be_a(ContentPackage)
            expect(assigns(:content_package)).to be_persisted
          end

          it "redirects to the created content_package" do
            post :create, {:content_package => valid_attributes}, valid_session
            expect(response).to redirect_to(edit_content_package_path(ContentPackage.last))
          end
        end

        context "with invalid params" do
          it "assigns a newly created but unsaved content_package as @content_package" do
            post :create, {:content_package => invalid_attributes}, valid_session
            expect(assigns(:content_package)).to be_a_new(ContentPackage)
          end

          it "re-renders the 'new' template" do
            post :create, {:content_package => invalid_attributes}, valid_session
            expect(response).to render_template("new")
          end
        end
      end

      describe "PUT #update" do
        context "with valid params" do
          let(:new_attributes) {
            {name: 'New name'}
          }

          it "updates the requested content_package" do
            content_package = ContentPackage.create! valid_attributes
            put :update, {:id => content_package.to_param, :content_package => new_attributes}, valid_session
            content_package.reload
            expect(assigns(:content_package).name).to eq('New name')
          end

          it "assigns the requested content_package as @content_package" do
            content_package = ContentPackage.create! valid_attributes
            put :update, {:id => content_package.to_param, :content_package => valid_attributes}, valid_session
            expect(assigns(:content_package)).to eq(content_package)
          end

          it "redirects to the content_package" do
            content_package = ContentPackage.create! valid_attributes
            put :update, {:id => content_package.to_param, :content_package => valid_attributes}, valid_session
            expect(response).to redirect_to(content_package)
          end
        end

        context "with invalid params" do
          it "assigns the content_package as @content_package" do
            content_package = ContentPackage.create! valid_attributes
            put :update, {:id => content_package.to_param, :content_package => invalid_attributes}, valid_session
            expect(assigns(:content_package)).to eq(content_package)
          end

          it "re-renders the 'edit' template" do
            content_package = ContentPackage.create! valid_attributes
            put :update, {:id => content_package.to_param, :content_package => invalid_attributes}, valid_session
            expect(response).to render_template("edit")
          end
        end
      end

      describe "DELETE #destroy" do
        it "destroys the requested content_package" do
          content_package = ContentPackage.create! valid_attributes
          expect {
            delete :destroy, {:id => content_package.to_param}, valid_session
          }.to change(ContentPackage, :count).by(-1)
        end

        it "redirects to the content_packages list" do
          content_package = ContentPackage.create! valid_attributes
          delete :destroy, {:id => content_package.to_param}, valid_session
          expect(response).to redirect_to(deleted_content_packages_path)
        end
      end
    end
  end
end
