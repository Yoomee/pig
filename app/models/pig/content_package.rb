module Pig
  class ContentPackage < ActiveRecord::Base

    include Pig::Permalinkable
    include Pig::Concerns::Recordable
    include Pig::Concerns::Commentable
    include Pig::Concerns::Workflow
    include Pig::Concerns::Versionable

    # Because of this issue on awesome_nested_set it is very important that
    # acts_as_taggable_on comes before acts_as_nested_set
    # https://github.com/collectiveidea/awesome_nested_set/issues/213
    acts_as_taggable_on :acts_as_taggable_on_tags
    acts_as_taggable_on :taxonomy
    acts_as_nested_set touch: true, order_column: :position

    belongs_to :content_type
    has_and_belongs_to_many :personas, class_name: 'Pig::Persona'
    belongs_to :author, class_name: 'Pig::User'
    belongs_to :last_edited_by, class_name: 'Pig::User'
    belongs_to :requested_by, class_name: 'Pig::User'
    has_many :archived_children, -> { where("archived_at IS NOT NULL").order(:position, :id) }, :class_name => "ContentPackage", :foreign_key => 'parent_id'

    before_create :set_meta_title

    validates :name, :content_type, :requested_by, :next_review, :presence => true
    validate :required_attributes
    validate :lineage
    validate :validate_content_chunks

    delegate :content_attributes, :package_name, :view_name, :missing_view?, :viewless?, :to => :content_type

    delegate :tag_categories, to: :content_type

    dragonfly_accessor :meta_image

    default_scope -> { where(archived_at: nil).order(:position, :id) }
    scope :archived, -> { unscoped.where("archived_at IS NOT NULL").order("archived_at DESC") }
    scope :published, -> { where(:status => 'published').where('publish_at <= ? OR publish_at IS NULL', Date.today) }
    scope :expiring, -> { where('next_review < ?', Date.today) }
    # scope :without, (lambda do |ids_or_records|
    #   array = [*ids_or_records].collect{|i| i.is_a?(Integer) ? i : i.try(:id)}.reject(&:nil?)
    #   array.empty? ? scoped : where(["#{table_name}.id NOT IN (?)", array])
    # end)

    def build_content_chunk_methods
      if content_type
        content_attributes.each do |attribute|
          type_factory(attribute.field_type).new(self, attribute.slug, attribute.field_type)
        end
      end
      @chunk_methods_set = true
    end

    def content_type=(value)
      super(value)
      build_content_chunk_methods
    end

    def type_factory(field_type)
      Pig.const_get("#{field_type.camelize}Type")
      rescue NameError
        raise Pig::UnknownAttributeTypeError, "Unable to find attribute type class #{field_type}"
    end

    def version_date(timestamp)
      if timestamp
        paper_trail.version_at(Time.at(timestamp.to_i))
      else
        versions.last.reify
      end
    end

    class << self

      def member_routes
        # Define all routes set up by "resources :content_packages"
        # We have to include the route so that we know if its the
        # url path or the http verb that defines the action
        resourceful_routes = [
          { :route => 'edit', :action => 'edit',    :method => 'get'},
          { :route => '',     :action => 'update',  :method => "#{Rails::VERSION::MAJOR >= 4 ? 'patch' : 'put'}"},
          { :route => '',     :action => 'destroy', :method => 'delete'},
          { :route => '',     :action => 'show',    :method => 'get'}
        ]

        # Get all the routes that match /content_packages/:id/:action
        routes = Rails.application.routes.routes.select do |route|
          /\/content_packages\/:id\/(\w+)/.match(route.path.spec.to_s)
        end

        # Project each route in to a hash of format: {:action => "children", :method => "get"}
        routes = routes.map do |x|
          { :route => x.defaults[:action], :action => x.defaults[:action], :method => x.verb.source.gsub(/[^0-9A-Za-z]/, '').downcase }
        end

        # Return a joint array of resourceful routes as well as defined member routes
        routes | resourceful_routes
      end

      def search(term)
        escaped_term = "%#{term}%"
        joins(:permalink).where(archived_at: nil).where("name LIKE ? OR pig_permalinks.path LIKE ?", escaped_term, escaped_term)
      end

      def parent_dropdown_cache_key
        "cp/parent-dropdown"
      end

      def with_content_type_name(name)
        joins(:content_type).where(pig_content_types: { name: name })
      end
    end

    def taxonomy_tags=(tags)
      tags.keys.each do |category|
        TagCategory.find_by_slug(category).tag(self, with: tags[category], on: 'taxonomy')
      end
    end

    def deletable?
      !archived? && slug.blank? && (children.empty? || children.all?(&:deletable?))
    end

    def archive
      return true if archived?
      if deletable?
        update_attribute(:archived_at, Time.now)
        children.all.each do |child|
          child.editing_user = editing_user
          child.archive
        end
      else
        false
      end
    end

    def archived?
      archived_at.present?
    end

    def expiring?
      next_review <  Date.today
    end

    def parents
      [parent, parent.try(:parents)].flatten.compact
    end

    def first_ancestor_with_view
      c = self
      result = nil
      while c.parent
        if !c.parent.viewless?
          result = c.parent
          break
        end
        c = c.parent
      end
      result
    end

    def published?
      (status == 'published') && (publish_at.nil? || publish_at <= Date.today)
    end

    def published_or_needs_updating?
      published? || status == "update"
    end

    def visible_to_user?(user)
      if logged_in_only?
        user && published? && !archived?
      else
        published? && !archived?
      end
    end

    def restore
      return true unless archived?
      deletion_occurred_at = archived_at.dup
      self.update_attribute(:archived_at, nil)
      archived_children.where("archived_at > ? AND archived_at < ?",deletion_occurred_at - 1.minute, deletion_occurred_at + 1.minute).each(&:restore)
    end

    def restore_warning
      archived_parents = parents.select(&:archived?)
      if archived_parents.empty?
        nil
      else
        "WARNING: One or more of this package's parents are #{t('actions.archived').downcase}. This package will not show in the sitemap unless you also restore #{archived_parents.map{|cp| "\"#{cp.name}\""}.to_sentence}."
      end
    end

    def to_s
      name
    end

    def to_param
      return id.to_s unless permalink
      permalink.full_path_without_leading_slash
    end

    def quick_build_permalink!
      return unless permalink.nil?
      permalink = build_permalink
      set_permalink
      set_permalink_full_path
      permalink.save
    end

    private

    def lineage
      return unless parent == self
      errors.add(:parent, 'can\'t be self')
    end

    def find_file_attribute_name(attribute_name)
      regexes = Regexp.union(/^retained_(.*)$/, /^remove_(.*)$/, /^(.*)_uid$/)
      attribute_name.scan(regexes).flatten.compact.first
    end

    def find_tags_attribute_name(attribute_name)
      regexes = Regexp.union(/^(.*)_list$/, /^(.*)_taggings$/)
      attribute_name.scan(regexes).flatten.compact.first || attribute_name # Default to attribute_name in order to fetch e.g. 'skills'
    end

    def required_attributes
      return true if new_record? || content_type.nil?
      content_attributes.each do |content_attribute|
        if content_attribute.required? && send(content_attribute.slug).blank?
          self.errors.add(:base, "#{content_attribute.name} can't be blank")
        end
      end
    end

    def set_meta_title
      self.meta_title = name
    end

    module PermalinkViewlessCheck
      def set_permalink
        content_type.try(:viewless?) ? true : super
      end
    end
    prepend PermalinkViewlessCheck

    def respond_to_missing?(method_name, include_private = false)
      return true if super
      if @chunk_methods_set
        false
      else
        build_content_chunk_methods
        respond_to? method_name
      end
    end

    def method_missing(method_sym, *arguments, &block)
      build_content_chunk_methods unless @chunk_methods_set
      if respond_to?(method_sym)
        send(method_sym, *arguments)
      else
        super(method_sym, *arguments, &block)
      end
    end

    def validate_content_chunks
      content_chunk_names.each do |chunk_name|
        self.send("#{chunk_name}_valid?", self)
      end
    end

    def content_chunk_names
      # Set intersect the json chunks with content attributes so we dont try
      # and validate an attribute that no longer exists.
      return [] if content_type.nil?
      (json_content["content_chunks"].try(:keys) || []) & content_attributes.pluck(:slug)
    end
  end
end
