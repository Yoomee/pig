module Pig
  class ContentPackage < ActiveRecord::Base

    # include YmCore::Model
    include Pig::Permalinkable
    include Pig::Concerns::Recordable

    belongs_to :content_type
    belongs_to :parent, :class_name => "ContentPackage"
    has_many :content_chunks, -> { includes :content_attribute }
    has_many :children, -> { where(:deleted_at => nil).order(:position, :id) }, :class_name => "ContentPackage", :foreign_key => 'parent_id'
    has_many :deleted_children, -> { where("deleted_at IS NOT NULL").order(:position, :id) }, :class_name => "ContentPackage", :foreign_key => 'parent_id'
    has_and_belongs_to_many :personas, class_name: 'Pig::Persona'
    belongs_to :author, :class_name => 'Pig::User'
    belongs_to :requested_by, :class_name => 'Pig::User'
    has_many :sir_trevor_images

    attr_accessor :skip_status_transition

    before_create :set_next_review
    before_save :set_status
    after_save :invalidate_parent_cache
    after_destroy :destroy_parent_cache

    validates :name, :content_type, :requested_by, :review_frequency, :presence => true
    validate :required_attributes
    validate :embeddable_attributes

    delegate :content_attributes, :package_name, :view_name, :missing_view?, :viewless?, :to => :content_type

    acts_as_taggable_on :acts_as_taggable_on_tags
    acts_as_taggable_on :taxonomy
    delegate :tag_categories, to: :content_type

    dragonfly_accessor :meta_image

    scope :root, -> { where(:parent_id => nil, :deleted_at => nil).order(:position, :id) }
    scope :published, -> { where(:status => 'published').where('publish_at <= ? OR publish_at IS NULL', Date.today) }
    scope :expiring, -> { where('next_review < ?', Date.today) }
    scope :without, (lambda do |ids_or_records|
      array = [*ids_or_records].collect{|i| i.is_a?(Integer) ? i : i.try(:id)}.reject(&:nil?)
      array.empty? ? scoped : where(["#{table_name}.id NOT IN (?)", array])
    end)

    after_initialize :build_content_chunk_methods

    def build_content_chunk_methods
      return if content_type.nil?
      content_attributes.each do |attribute|
        type_factory(attribute.field_type).new(self, attribute.slug, attribute.field_type)
      end
    end

    def content=(value)
      super(value)
      # https://github.com/rails/rails/issues/6127
      content_will_change! if Rails.version.to_f < 4.2
    end

    def content_type=(value)
      super(value)
      build_content_chunk_methods
    end

    def convert_chunks_to_content!
      content_chunks.each do |content_chunk|
        slug = content_chunk.content_attribute.slug
        value = content_chunk.attributes['value']
        send("#{slug}=", value)
      end
      save
    end

    def type_factory(field_type)
      Pig.const_get("#{field_type.camelize}Type")
      rescue NameError
        raise Pig::UnknownAttributeTypeError, "Unable to find attribute type class #{field_type}"
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

      def statuses(user)
        #TODO Permissions
        Hash.new.tap do |s|
          s[:draft] = 'Draft' if user.try(:role_is?, :developer) || user.try(:role_is?, :admin) || user.try(:role_is?, :editor)
          s[:pending] = 'Ready to review'
          s[:published] = 'Published' if user.try(:role_is?, :developer) || user.try(:role_is?, :admin) || user.try(:role_is?, :editor)
          s[:expiring] = 'Getting old' if user.try(:role_is?, :developer) || user.try(:role_is?, :admin) || user.try(:role_is?, :editor)
        end
      end

      def review_frequencies
        {
          :'1' => 'Monthly',
          :'2' => 'Every 2 Months',
          :'3' => 'Every 3 Months',
          :'6' => 'Every 6 Months'
        }
      end

      def search(term)
        escaped_term = "%#{term}%"
        joins(:permalink).where(deleted_at: nil).where("name LIKE ? OR pig_permalinks.path LIKE ?", escaped_term, escaped_term)
      end

      def parent_dropdown_cache_key
        "cp/parent-dropdown"
      end
    end

    def taxonomy_tags=(tags)
      tags.keys.each do |category|
        TagCategory.find_by_slug(category).tag(self, with: tags[category], on: 'taxonomy')
      end
    end

    def deletable?
      !deleted? && slug.blank? && (children.empty? || children.all?(&:deletable?))
    end

    def delete
      return true if deleted?
      if deletable?
        update_attribute(:deleted_at, Time.now)
        children.all.each do |child|
          child.editing_user = editing_user
          child.delete
        end
      else
        false
      end
    end

    def deleted?
      deleted_at.present?
    end

    def content_chunk_value_by_attribute_slug(slug)
      attribute = ContentAttribute.where(:content_type_id => content_type.id).where(:slug => slug).first
      chunk = content_chunks.select{|c|c.content_attribute.id == attribute.id}.first.try(:raw_value) || content_chunks.select{|c|c.content_attribute.id == attribute.default_attribute.try(:id)}.first.try(:raw_value)
      ActionController::Base.helpers.strip_tags(chunk)
    end

    def content_chunks
      @content_chunks ||= super.to_a
    end

    def parents
      [parent, parent.try(:parents)].flatten.compact
    end

    def ancestors
      result = []
      c = self
      while c.parent
        result.unshift(c.parent)
        c = c.parent
      end
      result
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

    def destroy_parent_cache
      Rails.cache.delete(ContentPackage.parent_dropdown_cache_key)
    end

    def invalidate_parent_cache
      if id_changed? || name_changed? || deleted_at_changed? || parent_id_changed?
        destroy_parent_cache
      end
    end

    def published?
      status == 'published' && (publish_at.nil? || publish_at <= Date.today)
    end

    def visible_to_user?(user)
      if logged_in_only?
        user && published? && !deleted? && !missing_view?
      else
        published? && !deleted? && !missing_view?
      end
    end

    def respond_to_with_content_attributes?(method_id, include_all = false)
      if method_id == :empty?
        return false
      end
      slug = method_id.to_s.sub(/^retained_/,'').sub(/^remove_/,'').sub(/_uid$/,'').chomp('=')
      if respond_to_without_content_attributes?(method_id, include_all)
        true
      elsif content_type
        return false if slug =~ /^_run__.*__callbacks$/
        slug_variants = [ slug, slug.chomp('_list').pluralize, slug.chomp('_url'), slug.chomp('_id'), slug.chomp('_lat_lng'), slug.chomp('_path') ]
        slug_variants.any?{|sl| content_attributes.exists?(:slug => sl)}
      else
        false
      end
    end
    alias_method_chain :respond_to?, :content_attributes

    def restore
      return true unless deleted?
      deletion_occurred_at = deleted_at.dup
      self.update_attribute(:deleted_at, nil)
      deleted_children.where("deleted_at > ? AND deleted_at < ?",deletion_occurred_at - 1.minute, deletion_occurred_at + 1.minute).each(&:restore)
    end

    def restore_warning
      deleted_parents = parents.select(&:deleted?)
      if deleted_parents.empty?
        nil
      else
        "WARNING: One or more of this package's parents are deleted. This package will not show in the sitemap unless you also restore #{deleted_parents.map{|cp| "\"#{cp.name}\""}.to_sentence}."
      end
    end

    def to_s
      name
    end

    private

    def content_chunk_for_content_attribute(content_attribute, initialise_if_nil = false)
      content_chunk = self.content_chunks.select{|c| c.content_attribute_id == content_attribute.id }.first
      if content_chunk.nil? && initialise_if_nil
        content_chunk = ContentChunk.new(:content_attribute => content_attribute, :content_package => self)
        self.content_chunks << content_chunk
      end
      content_chunk
    end

    def embeddable_attributes
      self.content_chunks.each do |content_chunk|
        if content_chunk.content_attribute
          if content_chunk.content_attribute.field_type.embeddable? && content_chunk.value_changed?
            if content_chunk.value.blank?
              content_chunk.value = nil
              content_chunk.html = nil
            else
              begin
                content_chunk.html = OEmbed::Providers.get(content_chunk.value).html
              rescue OEmbed::NotFound
                content_chunk.html = nil
                self.errors.add(content_chunk.content_attribute.slug + '_url', "No embeddable content found at this URL")
              end
            end
          end
        end
      end
    end

    def find_file_attribute_name(attribute_name)
      regexes = Regexp.union(/^retained_(.*)$/, /^remove_(.*)$/, /^(.*)_uid$/)
      attribute_name.scan(regexes).flatten.compact.first
    end

    def find_tags_attribute_name(attribute_name)
      regexes = Regexp.union(/^(.*)_list$/, /^(.*)_taggings$/)
      attribute_name.scan(regexes).flatten.compact.first || attribute_name # Default to attribute_name in order to fetch e.g. 'skills'
    end

    def get_value_for_content_attribute(content_attribute, method = nil)
      content_chunk = content_chunk_for_content_attribute(content_attribute)
      case content_attribute.field_type
      when 'boolean'
        instance_variable_set("@#{content_attribute.slug}".to_sym, content_chunk.try(:value) || false)
      when 'file', 'image'
        if method == 'path'
          content_chunk.try(:file).try(:url)
        else
          content_chunk.try(:file)
        end
      when 'link'
        instance_variable_set("@#{content_attribute.slug}".to_sym, content_chunk.try(:value))
      when 'embeddable'
        if method == 'url'
          instance_variable_set("@#{content_attribute.slug}_url".to_sym, content_chunk.try(:value))
        else
          instance_variable_set("@#{content_attribute.slug}".to_sym, content_chunk.try(:html).to_s.gsub('http://', 'https://').html_safe)
        end
      when 'user'
        if method == 'id'
          instance_variable_set("@#{content_attribute.slug}_id".to_sym, content_chunk.try(:raw_value))
        else
          instance_variable_set("@#{content_attribute.slug}".to_sym, content_chunk.try(:value))
        end
      when 'location'
        if method == 'lat_lng'
          instance_variable_set("@#{content_attribute.slug}_lat_lng".to_sym, content_chunk.try(:html).split(',').map { |e| e.to_f  })
        else
          instance_variable_set("@#{content_attribute.slug}".to_sym, content_chunk.try(:value))
        end
      when 'rich'
        instance_variable_set("@#{content_attribute.slug}".to_sym, content_chunk.try(:value))
      else
        instance_variable_set("@#{content_attribute.slug}".to_sym, content_chunk.try(:value).try(:html_safe))
      end

    end

    def required_attributes
      return true if new_record? || content_type.nil?
      content_attributes.each do |content_attribute|
        if content_attribute.required? && send(content_attribute.slug).blank?
          self.errors.add_on_blank(content_attribute.slug)
        end
      end
    end

    def save_content_chunks
      content_chunks.each(&:save)
    end

    def set_next_review
      self.next_review = Date.today + self.review_frequency.months
    end

    def set_permalink_with_viewless
      content_type.try(:viewless?) ? true : set_permalink_without_viewless
    end
    alias_method_chain(:set_permalink, :viewless)

    def set_status
      return if self.skip_status_transition
      if self.status_changed? && self.author_id then
        case self.status
        when 'draft'
          ContentPackageMailer.assigned(self, self.author).deliver
        when 'pending'
          self.author_id = nil
          ContentPackageMailer.assigned(self, self.requested_by).deliver
        end
      end
    end

    def set_value_for_content_attribute(content_attribute, value, method = nil)
      content_chunk = content_chunk_for_content_attribute(content_attribute, true)
      case content_attribute.field_type
      when 'boolean'
        content_chunk.value = [0, "0", false, "false", "", nil].include?(value) ? '0' : '1'
      when 'file', 'image'
        content_chunk.file = value
      when 'link'
        content_chunk.value = value.to_s
      when 'embeddable'
        if method == 'url'
          content_chunk.value = value
        else
          content_chunk.html = html
        end
      when 'location'
        if method == 'lat_lng'
          content_chunk.html = html
        else
          content_chunk.value = value
        end
      when 'user'
        if method == 'id'
          content_chunk.value = value
        else
          content_chunk.value = value.try(:id)
        end
      when 'rich'
        #strip out leading and trailing <p><br></p>
        data = JSON.parse(value)["data"]
        data.each do |block|
          if block["type"] == 'text'
            st = block["data"]["text"].gsub('<p><br></p>', '')
            block["data"]["text"] = st
          end
          # Sir Trevor wraps lists in <ul> tags when editing, remove them here else nested list hell occurs
          if block["type"] == 'list'
            st = block["data"]["text"].gsub('<ul>', '').gsub('</ul>', '')
            block["data"]["text"] = st
          end
        end
        content_chunk.value = JSON.generate({"data" => data})
      else
        content_chunk.value = value
      end
      instance_variable_set("@#{content_attribute.slug}".to_sym, content_chunk.value) unless %w{file image user}.include?(content_attribute.field_type)
    end

  end
end
