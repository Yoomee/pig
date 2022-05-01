module Pig
  module Admin
    class NavigationItemsController < Pig::Admin::ApplicationController
      load_and_authorize_resource class: 'Pig::NavigationItem'

      def create
        @navigation_item.save
        render :action => 'create_update'
      end

      def destroy
        @navigation_item.destroy
      end

      def edit
        render :action => 'new_edit'
      end

      def index
      end

      def new
        @navigation_item.parent_id = params[:parent_id]
        render :action => 'new_edit'
      end

      def reorder
        @navigation_items = @navigation_item.try(:children) || Pig::NavigationItem.root
      end

      def save_order
        params[:children_ids].each_with_index do |child_id, position|
          Pig::NavigationItem.find(child_id).update_attribute(:position, position)
        end
        redirect_to pig.admin_navigation_items_path
      end

      def search
        if defined?(Riddle)
          term = Riddle.escape(params[:term])
        else
          term = params[:term]
        end
        render :json => Pig::ContentPackage.search(term).includes(:permalink).map { |cp| {
            :id => cp.id,
            :label => cp.name.truncate(60),
            :value => cp.permalink_display_path
        }}
      end

      def update
        @navigation_item.update(params[:navigation_item])
        render :action => 'create_update'
      end

    end
  end
end
