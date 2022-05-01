module Pig
  class Ability
    include CanCan::Ability

    DEVELOPER_ABILITIES = {
      'Pig::ContentType' => [
        :manage_description,
        :manage_package_name,
        :manage_view_name,
        :manage_viewless,
        :manage_singleton
      ],
      'Pig::ContentPackage' => [
        :manage_slug
      ],
      'Pig::Permalink' => [
        :destroy
      ]
    }

    def initialize(user)
      can :home, Pig::ContentPackage
      can :show, Pig::ContentPackage do |content_package|
        content_package.visible_to_user?(nil)
      end

      return unless user

      can [:create, :index], RedactorImageUpload
      can [:edit, :show, :update], Pig::User, id: user.id
      if user.role_is?(:developer)
        can :manage, :all
      elsif user.role_is?(:admin)
        can :manage, :all
        cannot :alter_role, Pig::User
        can :alter_role, Pig::User do |other_user|
          other_user.role.to_sym.in?(user.available_roles)
        end
        DEVELOPER_ABILITIES.each do |klass, actions|
          actions.each do |action|
            cannot action, klass.constantize
          end
        end
        can :destroy, Pig::Permalink do |permalink|
          instance_exec permalink, &Pig.configuration.can_delete_permalink
        end
      elsif user.role_is?(:editor)
        can [:edit, :update], Pig::ContentPackage, :author_id => user.id
        can [:manage], Pig::ContentPackage
        cannot :destroy,  Pig::ContentPackage
        can [:index, :dashboard, :children], Pig::ContentType
        can [:create, :show], Pig::Permalink
        can :destroy, Pig::Permalink do |permalink|
          instance_exec permalink, &Pig.configuration.can_delete_permalink
        end
        can [:index, :edit], Pig::Persona
      elsif user.role_is?(:author)
        cannot :manage, Pig::Permalink
        can [:edit, :update], Pig::ContentPackage, :author_id => user.id
        can [:index, :show, :activity, :ready_to_review, :search, :preview], Pig::ContentPackage
        can [:index, :dashboard, :children], Pig::ContentType
        can :contributor_blog_posts, Pig::ContentPackage
        can [:children], Pig::ContentPackage
        can [:index, :edit], Pig::Persona
      end
    end
  end
end
