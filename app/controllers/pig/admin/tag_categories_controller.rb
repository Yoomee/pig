module Pig
  module Admin
    class TagCategoriesController < Pig::Admin::ApplicationController
      load_and_authorize_resource class: 'Pig::TagCategory'

      def new
      end

      def create
        if @tag_category.save
          redirect_to pig.admin_tag_categories_path
        else
          render :new, error: "Sorry there was a problem saving this category: #{@tag_category.errors.full_messages.to_sentence}"
        end
      end

      def edit
      end

      def index
      end

      def update
        if @tag_category.update(tag_category_params)
          redirect_to pig.admin_tag_categories_path
        else
          render 'edit'
        end
      end

      private

      def tag_category_params
        params.require(:tag_category).permit(:name, :slug, taxonomy_list: [])
      end
    end
  end
end
