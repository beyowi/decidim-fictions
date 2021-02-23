# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Fictions
    # This cell renders the linked resource of a fiction.
    class FictionLinkedResourcesCell < Decidim::ViewModel
      def show
        render if linked_resource
      end
    end
  end
end
