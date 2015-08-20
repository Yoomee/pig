require 'rails_helper'

module Pig
  RSpec.describe Admin::ContentTypesController, type: :routing do
    routes { Pig::Engine.routes }

    describe 'routing' do

      it 'routes to #index' do
        expect(get: '/admin/content_types').to route_to('pig/admin/content_types#index')
      end

      it 'routes to #new' do
        expect(get: '/admin/content_types/new').to route_to('pig/admin/content_types#new')
      end

      it 'routes to #edit' do
        expect(get: '/admin/content_types/1/edit').to route_to('pig/admin/content_types#edit', id: '1')
      end

      it 'routes to #create' do
        expect(post: '/admin/content_types').to route_to('pig/admin/content_types#create')
      end

      it 'routes to #update' do
        expect(put: '/admin/content_types/1').to route_to('pig/admin/content_types#update', id: '1')
      end

      it 'routes to #destroy' do
        expect(delete: '/admin/content_types/1').to route_to('pig/admin/content_types#destroy', id: '1')
      end

    end
  end
end
