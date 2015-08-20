module Pig
  class Permalink < ActiveRecord::Base

    include Pig::Concerns::Models::Core

    belongs_to :resource, :polymorphic => true

    validates :full_path, presence: true,
      uniqueness: { case_sensitive: false, scope: :active },
      format: {with: /\A\/[\/\w-]+\z/, message: 'should only use a-z, 0-9, -, _ and / characters'}
    validates :active, uniqueness:
      { scope: [:resource_id, :resource_type], if: proc { |p| p.active? } }
    validate :path_does_not_match_existing_route
    validate :path_is_valid_url

    after_update :create_inactive_permalink
    after_update :delete_duplicate_permalinks

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }

    def generate_unique_path!(title)
      if path.blank? && title.present?
        path_name_root = title.parameterize
        unique_path_name = path_name_root.dup
        permalinks = new_record? ? self.class : self.class.where("id != ?",self.id)
        count = 0
        while permalinks.exists?(:path => unique_path_name)
          count += 1
          unique_path_name = "#{path_name_root}-#{count}"
        end
        self.path = unique_path_name
      end
    end

    def resource_path
      "#{Pig::Engine.routes._generate_prefix({})}/#{resource_type.demodulize.tableize}/#{resource_id}"
    end

    def self.find_from_url(url)
      find_by_attr = Pig.configuration.nested_permalinks ? :full_path : :path
      permalink_path = "#{find_by_attr == :full_path ? '/' : ''}#{url}".squeeze('/').downcase
      # find_by_<method> is deprecated in rails 4
      if Rails::VERSION::MAJOR >= 4
        Permalink.find_by(find_by_attr => permalink_path)
      else
        Permalink.send("find_by_#{find_by_attr}", permalink_path)
      end
    end

    def to_param
      full_path.gsub!(/^\//, '')
    end

    private
    def create_inactive_permalink
      return unless path_changed? || full_path_changed?
      resource.permalinks.create(:active => false, :path => path_was, :full_path => full_path_was)
    end

    def delete_duplicate_permalinks
      Permalink.without(self).where(:path => path, :full_path => full_path, :active => false).delete_all
    end

    def path_does_not_match_existing_route
      existing_routes = Rails.application.routes.routes.collect do |route|
        if Pig.configuration.nested_permalinks
          route.path.spec.to_s.split(/\(/).try(:[],1)
        else
          route.path.spec.to_s.split(/\/|\(/).try(:[],1)
        end
      end.uniq.compact
      if existing_routes.include?(path)
        errors.add(:path, "has already been taken")
      end
    end

    def path_is_valid_url
      return unless active?
      if path.present? && (path != path.to_url.parameterize)
        errors.add(:path, "is invalid")
      end
    end

  end
end
