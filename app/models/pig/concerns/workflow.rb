require 'active_support/concern'

module Pig
  module Concerns
    module Workflow
      extend ActiveSupport::Concern

      included do
        before_save :execute_transition
      end

      module ClassMethods
        def statuses(user)
          statuses_for(user, self)
        end

        def check_ability(ability, instance, user)
          (ability || user).can? :manage, instance
        end

        def statuses_for(user, instance, ability = nil)
          statuses = {}
          statuses[:draft] = 'Draft' if check_ability(ability, instance, user)
          statuses[:pending] = 'Ready to review'
          statuses[:published] = 'Published' if check_ability(ability, instance, user)
          statuses[:expiring] = 'Getting old' if check_ability(ability, instance, user)
          statuses
        end

      end

      def statuses(user, ability)
        self.class.statuses_for(user, self, ability)
      end

      def execute_transition
        return unless status_changed?
        transitions = {
          draft: {
            pending: :ready_to_review
          },
          pending: {
            draft: :assign_to_author
          },
          published: {
            draft: :assign_to_author
          }
        }
        event = transitions[status_was.to_sym][status.to_sym]
        send(event) if event
      end

      def ready_to_review
        self.author_id = nil
        ContentPackageMailer.assigned(self, requested_by).deliver
      end

      def assign_to_author
        ContentPackageMailer.assigned(self, author).deliver
      end

    end
  end
end
