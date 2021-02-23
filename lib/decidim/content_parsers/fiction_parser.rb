# frozen_string_literal: true

module Decidim
  module ContentParsers
    # A parser that searches mentions of Fictions in content.
    #
    # This parser accepts two ways for linking Fictions.
    # - Using a standard url starting with http or https.
    # - With a word starting with `~` and digits afterwards will be considered a possible mentioned fiction.
    # For example `~1234`, but no `~ 1234`.
    #
    # Also fills a `Metadata#linked_fictions` attribute.
    #
    # @see BaseParser Examples of how to use a content parser
    class FictionParser < BaseParser
      # Class used as a container for metadata
      #
      # @!attribute linked_fictions
      #   @return [Array] an array of Decidim::Fictions::Fiction mentioned in content
      Metadata = Struct.new(:linked_fictions)

      # Matches a URL
      URL_REGEX_SCHEME = '(?:http(s)?:\/\/)'
      URL_REGEX_CONTENT = '[\w.-]+[\w\-\._~:\/?#\[\]@!\$&\'\(\)\*\+,;=.]+'
      URL_REGEX_END_CHAR = '[\d]'
      URL_REGEX = %r{#{URL_REGEX_SCHEME}#{URL_REGEX_CONTENT}/fictions/#{URL_REGEX_END_CHAR}+}i.freeze
      # Matches a mentioned Fiction ID (~(d)+ expression)
      ID_REGEX = /~(\d+)/.freeze

      def initialize(content, context)
        super
        @metadata = Metadata.new([])
      end

      # Replaces found mentions matching an existing
      # Fiction with a global id for that Fiction. Other mentions found that doesn't
      # match an existing Fiction are returned as they are.
      #
      # @return [String] the content with the valid mentions replaced by a global id.
      def rewrite
        rewrited_content = parse_for_urls(content)
        parse_for_ids(rewrited_content)
      end

      # (see BaseParser#metadata)
      attr_reader :metadata

      private

      def parse_for_urls(content)
        content.gsub(URL_REGEX) do |match|
          fiction = fiction_from_url_match(match)
          if fiction
            @metadata.linked_fictions << fiction.id
            fiction.to_global_id
          else
            match
          end
        end
      end

      def parse_for_ids(content)
        content.gsub(ID_REGEX) do |match|
          fiction = fiction_from_id_match(Regexp.last_match(1))
          if fiction
            @metadata.linked_fictions << fiction.id
            fiction.to_global_id
          else
            match
          end
        end
      end

      def fiction_from_url_match(match)
        uri = URI.parse(match)
        return if uri.path.blank?

        fiction_id = uri.path.split("/").last
        find_fiction_by_id(fiction_id)
      rescue URI::InvalidURIError
        Rails.logger.error("#{e.message}=>#{e.backtrace}")
        nil
      end

      def fiction_from_id_match(match)
        fiction_id = match
        find_fiction_by_id(fiction_id)
      end

      def find_fiction_by_id(id)
        if id.present?
          spaces = Decidim.participatory_space_manifests.flat_map do |manifest|
            manifest.participatory_spaces.call(context[:current_organization]).public_spaces
          end
          components = Component.where(participatory_space: spaces).published
          Decidim::Fictions::Fiction.where(component: components).find_by(id: id)
        end
      end
    end
  end
end
