# frozen_string_literal: true

module Decidim
  module Fictions
    # This helper include some methods for rendering fictions dynamic maps.
    module MapHelper
      include Decidim::ApplicationHelper
      # Serialize a collection of geocoded fictions to be used by the dynamic map component
      #
      # geocoded_fictions - A collection of geocoded fictions
      def fictions_data_for_map(geocoded_fictions)
        geocoded_fictions.map do |fiction|
          fiction.slice(:latitude, :longitude, :address).merge(title: present(fiction).title,
                                                                body: truncate(present(fiction).body, length: 100),
                                                                icon: icon("fictions", width: 40, height: 70, remove_icon_class: true),
                                                                link: fiction_path(fiction))
        end
      end
    end
  end
end
