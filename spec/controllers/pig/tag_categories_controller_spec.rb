require 'rails_helper'

module Pig
  RSpec.describe Admin::TagCategoriesController, type: :controller do
    routes { Pig::Engine.routes }
    render_views

    let(:valid_attributes) do
      FactoryGirl.attributes_for(:tag_category)
    end

    let(:invalid_attributes) do
      { name: '' }
    end

    # This should return the minimal set of values that should be in the session
    # in order to pass any filters (e.g. authentication) defined in
    # TagCategoriesController. Be sure to keep this updated too.
    let(:valid_session) { {} }

    requests = %w(index new edit update create)
    let(:index) { get :index }
    let(:new) { get :new }
    let(:edit) { get :edit, id: FactoryGirl.create(:tag_category).id }
    let(:update) {
      patch :update,
            id: FactoryGirl.create(:tag_category).id,
            tag_category: FactoryGirl.attributes_for(:tag_category)
    }
    let(:create) { post :create, tag_category: FactoryGirl.attributes_for(:tag_category) }

    context 'not signed in' do
      requests.each do |request|
        it 'should redirect #{request} to sign in' do
          eval(request)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'signed in with user of role without permission to view page' do
      login_no_role

      requests.each do |request|
        it 'should redirect #{request} to not authorized page' do
          eval(request)
          expect(response).to redirect_to(admin_not_authorized_path)
        end
      end
    end

    context 'signed in as an admin' do
      login_admin
      describe 'GET #index' do
        it 'assigns all tag_categories as @tag_categories' do
          tag_category = TagCategory.create! valid_attributes
          get :index, {}, valid_session
          expect(assigns(:tag_categories)).to eq([tag_category])
        end
      end

      describe 'GET #new' do
        it 'should render the form partial' do
          get :new, {}, valid_session
          expect(response).to render_template(partial: '_form')
        end

        it 'assigns a new tag_category as @tag_category' do
          get :new, {}, valid_session
          expect(assigns(:tag_category)).to be_a_new(TagCategory)
        end
      end

      describe 'GET #edit' do
        it 'should render the form partial' do
          tag_category = TagCategory.create! valid_attributes
          get :edit, { id: tag_category.to_param }, valid_session
          expect(response).to render_template(partial: '_form')
        end

        it 'assigns the requested tag_category as @tag_category' do
          tag_category = TagCategory.create! valid_attributes
          get :edit, { id: tag_category.to_param }, valid_session
          expect(assigns(:tag_category)).to eq(tag_category)
        end
      end

      describe 'POST #create' do
        context 'with valid params' do
          it 'creates a new TagCategory' do
            expect do
              post :create, { tag_category: valid_attributes }, valid_session
            end.to change(TagCategory, :count).by(1)
          end

          it 'assigns a newly created tag_category as @tag_category' do
            post :create, { tag_category: valid_attributes }, valid_session
            expect(assigns(:tag_category)).to be_a(TagCategory)
            expect(assigns(:tag_category)).to be_persisted
          end

          it 'redirects to the created tag_category' do
            post :create, { tag_category: valid_attributes }, valid_session
            expect(response).to redirect_to(admin_tag_categories_path)
          end
        end

        context 'with invalid params' do
          it 'assigns a newly created but unsaved tag_category as @tag_category' do
            post :create, { tag_category: invalid_attributes }, valid_session
            expect(assigns(:tag_category)).to be_a_new(TagCategory)
          end

          it "re-renders the 'new' template" do
            post :create, { tag_category: invalid_attributes }, valid_session
            expect(response).to render_template('new')
          end
        end
      end

      describe 'PUT #update' do
        context 'with valid params' do
          let(:new_attributes) do
            { name: 'Foobar' }
          end

          it 'updates the requested tag_category' do
            tag_category = TagCategory.create! valid_attributes
            put :update, { id: tag_category.to_param, tag_category: new_attributes }, valid_session
            tag_category.reload
            expect(tag_category.name).to eq('Foobar')
          end

          it 'assigns the requested tag_category as @tag_category' do
            tag_category = TagCategory.create! valid_attributes
            put :update, { id: tag_category.to_param, tag_category: valid_attributes }, valid_session
            expect(assigns(:tag_category)).to eq(tag_category)
          end

          it 'redirects to the tag_category' do
            tag_category = TagCategory.create! valid_attributes
            put :update, { id: tag_category.to_param, tag_category: valid_attributes }, valid_session
            expect(response).to redirect_to(admin_tag_categories_path)
          end

          it 'deletes taggings that are not used' do
            tag_category = TagCategory.create! valid_attributes.merge(taxonomy_list: ['Foo', 'Bar'])

            put :update, { id: tag_category.to_param, tag_category: valid_attributes.merge(taxonomy_list: ['Foo']) }, valid_session
            tag_count = ActsAsTaggableOn::Tagging.where(tagger: tag_category, tag: ActsAsTaggableOn::Tag.where(name: 'Bar')).count
            expect(tag_count).to eq(0)
          end
        end

        context 'with invalid params' do
          it 'assigns the tag_category as @tag_category' do
            tag_category = TagCategory.create! valid_attributes
            put :update, { id: tag_category.to_param, tag_category: invalid_attributes }, valid_session
            expect(assigns(:tag_category)).to eq(tag_category)
          end

          it "re-renders the 'edit' template" do
            tag_category = TagCategory.create! valid_attributes
            put :update, { id: tag_category.to_param, tag_category: invalid_attributes }, valid_session
            expect(response).to render_template('edit')
          end
        end
      end
    end
  end
end
