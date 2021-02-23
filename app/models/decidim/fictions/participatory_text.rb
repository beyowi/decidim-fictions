# frozen_string_literal: true

module Decidim
  module Fictions
    # Contains the meta data of the document, like title and description.
    #
    class ParticipatoryText < Fictions::ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Traceable
      include Decidim::Loggable
    end
  end
end
