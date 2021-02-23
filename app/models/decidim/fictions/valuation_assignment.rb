# frozen_string_literal: true

module Decidim
  module Fictions
    # A valuation assignment links a fiction and a Valuator user role.
    # Valuators will be users in charge of defining the monetary cost of a
    # fiction.
    class ValuationAssignment < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :fiction, foreign_key: "decidim_fiction_id", class_name: "Decidim::Fictions::Fiction"
      belongs_to :valuator_role, polymorphic: true

      def self.log_presenter_class_for(_log)
        Decidim::Fictions::AdminLog::ValuationAssignmentPresenter
      end

      def valuator
        valuator_role.user
      end
    end
  end
end
