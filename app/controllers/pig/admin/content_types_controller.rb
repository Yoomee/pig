module Pig
  module Admin
    class ContentTypesController < Pig::Admin::ApplicationController

      load_and_authorize_resource class: 'Pig::ContentType'
      skip_load_resource :only => :create

      def children
      end

      def create
        params = content_type_params
        @content_type = Pig::ContentType.new
        @content_type.assign_attributes(params)
        if @content_type.save
          redirect_to pig.admin_content_types_path
        else
          render action: 'new'
        end
      end

      def destroy
        if @content_type.destroy
          flash[:notice] = "The content template was successfully deleted"
        else
          flash[:error] = "Unable to delete this content template"
        end
        redirect_to pig.admin_content_types_path
      end

      def dashboard
        @activity_items = Pig::ActivityItem.where(:resource_type => "Pig::ContentPackage").paginate(:page => 1, :per_page => 5)
        @my_content = Pig::ContentPackage.where("author_id = :user_id OR (requested_by_id = :user_id and status = 'pending')", user_id: current_user.try(:id)).order('due_date, id')
      end

      def duplicate
        seed = @content_type
        if params[:to]
          @content_type = Pig::ContentType.find(params[:to])
        else
          @content_type = Pig::ContentType.new
        end
        first_position = @content_type.content_attributes.size
        seed.content_attributes.each_with_index do |content_attribute, idx|
          @content_type.content_attributes.build(content_attribute.attributes.slice(*ContentAttribute.fields_to_duplicate).merge(:position => first_position + idx))
        end
        render :action => @content_type.new_record? ? 'new' : 'edit'
      end

      def edit
        @content_type.content_attributes.build if @content_type.content_attributes.count.zero?
      end

      def index
        @content_types = Pig::ContentType.order(:name)
      end

      def new
        @content_type.content_attributes.build
      end

      def reorder
      end

      def save_order
        params[:content_attribute_ids].each_with_index do |content_attribute_id, position|
          Pig::ContentAttribute.find(content_attribute_id).update_attribute(:position, position)
        end
        redirect_to pig.admin_content_packages_path(:anchor => 'content-types')
      end

      def update
        params = content_type_params
        if @content_type.update(params)
          redirect_to pig.admin_content_types_path
        else
          flash[:error] = @content_type.errors.full_messages.to_sentence
          render :action => 'edit'
        end
      end

      private

      def content_type_params
        params[:content_type][:content_attributes_attributes] ||= []
        params.require(:content_type).permit(
          :name,
          :description,
          :singleton,
          :package_name,
          :viewless,
          :view_name,
          :tag_category_ids => [],
          :content_attributes_attributes => [
            :id,
            :_destroy,
            :default_attribute_id,
            :name,
            :description,
            :field_type,
            :required,
            :meta,
            :meta_tag_name,
            :limit_quantity,
            :limit_unit,
            :position,
            :resource_content_type_id
          ]
        )
      end
    end
  end
end
