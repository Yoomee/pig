module Pig
  module Admin
    class ContentTypesController < Pig::Admin::ApplicationController

      load_and_authorize_resource class: 'Pig::ContentType'
      skip_load_resource :only => :create

      def children
      end

      def create
        params = content_type_params
        params = convert_sir_trevor_settings(params)
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
        @my_content = Pig::ContentPackage.where(:author_id => current_user.try(:id)).order('due_date, id')
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

      def convert_sir_trevor_settings(params)
        # Replace sir trevor params with JSON
        params["content_attributes_attributes"].each do |content_attributes_params|
          ca_id = content_attributes_params[0]
          content_attributes = content_attributes_params[1].with_indifferent_access
          if content_attributes.has_key? "sir_trevor_settings"
            content_attributes["sir_trevor_settings"] = sir_trevor_settings_to_json(content_attributes["sir_trevor_settings"])
            params["content_attributes_attributes"][ca_id] = content_attributes
          end
        end
        params
      end

      def sir_trevor_settings_to_json(settings)
        # Convert Sir Trevor form fields to JSON so content_type.update_attributes works
        j = {}
        Pig::ContentAttribute::DEFAULT_SIR_TREVOR_BLOCK_TYPES.each do |block_type|
          j[block_type] = {:required => (settings.has_key? "#{block_type}_required"), :limit => settings["#{block_type}_limit"] }
        end
        json = JSON.generate(j)
        json
      end

      def update
        params = content_type_params
        params = convert_sir_trevor_settings(params)
        if @content_type.update_attributes(params)
          redirect_to pig.admin_content_types_path
        else
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
          :use_workflow,
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
            :resource_content_type_id,
            :sir_trevor_settings => Pig::ContentAttribute::DEFAULT_SIR_TREVOR_BLOCK_TYPES.map {|e| ["#{e}_required", "#{e}_limit"] }.flatten
          ]
        )
      end
    end
  end
end
