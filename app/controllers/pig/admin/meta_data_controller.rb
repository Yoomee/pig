module Pig
  module Admin
    class MetaDataController < Pig::Admin::ApplicationController

      layout 'pig/application'
      load_and_authorize_resource class: 'Pig::MetaDatum'

      def create
        if @meta_datum.save
          redirect_to [pig, :admin, @meta_datum]
        else
          render :new, error: "Sorry there was a problem saving this page: #{@meta_datum.errors.full_messages.to_sentence}"
        end
      end

      def destroy
        if @meta_datum.destroy
          flash[:notice] = "Destroyed \"#{@meta_datum}\""
        else
          flash[:error] = "\"#{@meta_datum}\" couldn't be destroyed"
        end
        redirect_to pig.admin_meta_data_path
      end

      def edit
      end

      def index
      end

      def new
      end

      def show
      end

      def update
        if @meta_datum.update_attributes(meta_datum_params)
          redirect_to pig.admin_meta_datum_path(@meta_datum), notice: "Updated \"#{@meta_datum}\""
        else
          render :edit, error: "Sorry there was a problem saving this page: #{@meta_datum.errors.full_messages.to_sentence}"
        end
      end

      private

      def meta_datum_params
        params.require(:meta_datum).permit(:page_slug, :title, :description, :keywords, :image, :remove_image, :retained_image)
      end

    end
  end
end
