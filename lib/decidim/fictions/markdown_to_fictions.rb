# frozen_string_literal: true

require "redcarpet"

module Decidim
  module Fictions
    # This class parses a participatory text document in markdown and
    # produces Fictions in the form of sections and articles.
    #
    # This implementation uses Redcarpet Base renderer.
    # Redcarpet::Render::Base performs a callback for every block it finds, what MarkdownToFictions
    # does is to implement callbacks for the blocks which it is interested in performing some actions.
    #
    class MarkdownToFictions < ::Redcarpet::Render::Base
      # Public: Initializes the serializer with a fiction.
      def initialize(component, current_user)
        super()
        @component = component
        @current_user = current_user
        @last_position = 0
        @num_sections = 0
        @list_items = []
      end

      def parse(document)
        renderer = self
        extensions = {
          # no lax_spacing so that it is easier to group paragraphs in articles.
          lax_spacing: false,
          fenced_code_blocks: true,
          autolink: true,
          underline: true
        }
        parser = ::Redcarpet::Markdown.new(renderer, extensions)
        parser.render(document)
      end

      ##########################################
      # Redcarpet callbacks
      ##########################################

      # Block-level calls ######################

      # Recarpet callback to process headers.
      # Creates Paricipatory Text Fictions at Section and Subsection levels.
      def header(title, level)
        participatory_text_level = if level > 1
                                     Decidim::Fictions::ParticipatoryTextSection::LEVELS[:sub_section]
                                   else
                                     Decidim::Fictions::ParticipatoryTextSection::LEVELS[:section]
                                   end

        create_fiction(title, title, participatory_text_level)

        @num_sections += 1
        title
      end

      # Recarpet callback to process paragraphs.
      # Creates Paricipatory Text Fictions at Article level.
      def paragraph(text)
        return if text.blank?

        create_fiction(
          (@last_position + 1 - @num_sections).to_s,
          text,
          Decidim::Fictions::ParticipatoryTextSection::LEVELS[:article]
        )

        text
      end

      # Render the list as a whole
      def list(_contents, list_type)
        return if @list_items.empty?

        body = case list_type
               when :ordered
                 @list_items.collect.with_index { |item, idx| "#{idx + 1}. #{item}\n" }.join
               else
                 @list_items.collect { |item| "- #{item}\n" }.join
               end
        # reset items for the next list
        @list_items = []
        create_fiction(
          (@last_position + 1 - @num_sections).to_s,
          body,
          Decidim::Fictions::ParticipatoryTextSection::LEVELS[:article]
        )

        body
      end

      # do not render list items, save them for rendering with the whole list
      def list_item(text, _list_type)
        @list_items << text.strip
        nil
      end

      # Span-level calls #######################

      def link(link, title, content)
        attrs = %(href="#{link}")
        attrs += %( title="#{title}") if title.present?
        "<a #{attrs}>#{content}</a>"
      end

      def image(link, title, alt_text)
        attrs = %(src="#{link}")
        attrs += %( alt="#{alt_text}") if alt_text.present?
        attrs += %( title="#{title}") if title.present?
        "<img #{attrs}/>"
      end

      def emphasis(text)
        "<em>#{text}</em>"
      end

      def double_emphasis(text)
        "<strong>#{text}</strong>"
      end

      def underline(text)
        "<u>#{text}</u>"
      end

      private

      # Prevents PaperTrail from creating versions while producing fictions from a document.
      # A first version will be created when publishing the Participatory Text.
      def create_fiction(title, body, participatory_text_level)
        attributes = {
          component: @component,
          title: title,
          body: body,
          participatory_text_level: participatory_text_level
        }

        PaperTrail.request(enabled: false) do
          fiction = Decidim::Fictions::FictionBuilder.create(
            attributes: attributes,
            author: @component.organization,
            action_user: @current_user
          )

          @last_position = fiction.position

          fiction
        end
      end
    end
  end
end
