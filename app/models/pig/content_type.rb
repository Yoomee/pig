module Pig
  class ContentType < ActiveRecord::Base

    has_many :content_attributes, -> { order(:position, :id) }
    has_many :content_packages, -> { where(:deleted_at => nil)}
    has_many :dependent_content_packages, class_name: 'Pig::ContentPackage',
      foreign_key: 'content_type_id'
    has_many :resource_tag_categories, as: :taggable_resource
    has_many :tag_categories, through: :resource_tag_categories

    validates :name, uniqueness: true, presence: true
    accepts_nested_attributes_for :content_attributes, :allow_destroy => true
    before_create(:set_content_attribute_positions)
    before_destroy(:destroyable?)

    scope :viewless, -> { where(:viewless)}
    scope :not_viewless, -> { where(:viewless => false)}

    default_scope -> { includes(:content_attributes) }

    def destroyable?
      dependent_content_packages.count.zero?
    end

    def missing_view?
      if viewless?
        false
      else
        view_found = false
        ActionController::Base.view_paths.all? do |path|
          ActionView::Template.template_handler_extensions.each do |extension|
            view_found = File.exists?("#{path}/pig/templates/#{view_name}.html.#{extension}")
            break if view_found
          end
        end
        !view_found
      end
    end

    def package_name
      read_attribute(:package_name).presence || name.try(:downcase)
    end

    def to_s
      name
    end

    private
    def set_content_attribute_positions
      self.content_attributes.each_with_index do |content_attribute, idx|
        content_attribute.position = idx
      end
    end

  end
end
