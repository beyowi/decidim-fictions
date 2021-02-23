# frozen-string_literal: true

module Decidim
  module Fictions
    class AcceptedFictionEvent < Decidim::Events::SimpleEvent
      include Decidim::Events::AuthorEvent

      def resource_text
        translated_attribute(resource.answer)
      end

      def event_has_roles?
        true
      end
    end
  end
end
