# frozen-string_literal: true

module Decidim
  module Fictions
    class EvaluatingFictionEvent < Decidim::Events::SimpleEvent
      def event_has_roles?
        true
      end
    end
  end
end
