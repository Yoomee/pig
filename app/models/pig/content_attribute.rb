module Pig
  class ContentAttribute < ActiveRecord::Base

    belongs_to :content_type
    belongs_to :default_attribute, :class_name => 'ContentAttribute'
    after_validation :set_meta_title, :if => :meta?
    after_validation :set_slug
    validates :slug, :name, :field_type, :presence => true
    begin
      validates :slug, :name,
        uniqueness: { scope: :content_type_id },
        exclusion: {
          in: Pig::ContentPackage.methods + Pig::ContentPackage.column_names,
          message: "%{value} is a reserved word."
        }
    rescue ActiveRecord::StatementInvalid
      # Migrations not yet carried out, but need to be able to precompile
    end
    belongs_to :resource_content_type, :class_name => 'ContentType'


    class << self

      def field_types
        {
          :string => 'Single line of text',
          :text => 'Block of text',
          :link => 'Link',
          :image => 'Image',
          :file => 'File',
          :embeddable => 'Embeddable content - Flickr, Instagram, Scribd, Slideshare, SoundCloud, Vimeo, YouTube',
          :tags => 'Tag list',
          :boolean => 'Check box',
          :user => "User",
          :location => "Location",
          :rich => "Rich content (Sir Trevor)",
          :resource => "Link to content",
          :rich_content => "Rich Content",
          :date => "Date",
          :time => "Time"
        }
      end

      def fields_to_duplicate
        column_names - %w{id content_type_id slug position}
      end

    end

    DEFAULT_SIR_TREVOR_BLOCK_TYPES = ['Text', 'Image', 'Video', 'Heading', 'Quote', 'List', 'Alert']
    META_TAG_TYPES = ["title", "description", "image", "keywords"]

    def field_type
      ActiveSupport::StringInquirer.new(read_attribute(:field_type).to_s)
    end

    def input_type
      case field_type
      when 'file' then 'file_with_preview'
      when 'text' then 'redactor'
      when 'boolean' then 'content_boolean'
      when 'user' then 'select'
      when 'resource' then 'autocomplete_select'
      when 'rich' then 'text'
      when 'rich_content' then 'rich_redactor'
      when 'date' then 'date_picker'
      when 'time' then 'ym_time_picker'
      else field_type
      end
    end

    def input_method
      case field_type
      when 'embeddable' then slug + "_url"
      when 'tags' then slug.singularize + "_list"
      when 'user' then slug + "_id"
      else slug
      end
    end

    def input_options
      case field_type
      when 'user'
        {
          :collection => Pig::User.all,
          :prompt => "None selected"
        }
      when 'resource'
        {
          :collection => resource_collection,
          :prompt => "None selected",
        }
      else {}
      end
    end

    def resource_collection
      # ContentPackage collection for atrributes of type resource
      resource_content_type.nil? ? ContentPackage.published : ContentPackage.where(content_type: resource_content_type).published
    end

    def limitable?
      %w{string text}.include?(field_type.to_s)
    end

    def removable?
      new_record? || content_type.missing_view?
    end

    def sir_trevor_settings_json
      if sir_trevor_settings
        j = JSON.parse(sir_trevor_settings)
        DEFAULT_SIR_TREVOR_BLOCK_TYPES.each do |block_type|
          unless j.has_key? block_type
            j[block_type] = {:required => false, :limit => 0 }
          end
        end
      else
        j = {}
        DEFAULT_SIR_TREVOR_BLOCK_TYPES.each do |block_type|
          j[block_type] = {:required => false, :limit => 0 }
        end
      end
      HashWithIndifferentAccess.new(j)
    end

    def sir_trevor_limit_data
      # Hash to give to Sir Trevor JS initialize options
      settings = sir_trevor_settings_json
      block_type_limits = {}
      settings.map {|k,v| block_type_limits[k] = v["limit"]}
      {
        :blockTypeLimits => block_type_limits,
        :blockTypes => settings.reject{|k,v| v["limit"] == "0" }.keys,
        :required => settings.reject{|k,v| v["required"] == false }.keys
      }
    end

    def to_s
      name
    end

    private

    def set_meta_title
      unless name.start_with?('Meta ')
        self.name = 'Meta ' << name
        valid?
      end
    end

    def set_slug
      return unless slug.blank? && name.present? && errors['name'].blank?
      slug_name = name.gsub('-', ' ').parameterize('_').sub(/^\d+/, 'n')
      if Pig::ContentPackage.new.respond_to?(slug_name)
        slug_name = 'content_package_' + slug_name
      end
      self.slug = slug_name
      valid?
    end

  end
end
