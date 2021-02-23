# frozen_string_literal: true

module Decidim
  module Fictions
    module Amendable
      # A command with all the business logic when a user starts amending a resource.
      module CreateExtend

        def emendation_attributes
          fields = {}

          parsed_title = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.title, current_organization: form.current_organization).rewrite
          parsed_body = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.body, current_organization: form.current_organization).rewrite

          fields[:title] = parsed_title
          fields[:body] = parsed_body
          fields[:component] = @amendable.component

          fields[:published_at] = Time.current if form.emendation_type.constantize.new().is_a?(Decidim::Amendable)
          fields
        end

      end
    end
  end
end

Decidim::Amendable::Create.class_eval do
  prepend(Decidim::Fictions::Amendable::CreateExtend)
end