# frozen_string_literal: true

require "decidim/fictions/admin"
require "decidim/fictions/engine"
require "decidim/fictions/admin_engine"
require "decidim/fictions/component"
require "acts_as_list"

module Decidim
  # This namespace holds the logic of the `Fictions` component. This component
  # allows users to create fictions in a participatory process.
  module Fictions
    autoload :FictionSerializer, "decidim/fictions/fiction_serializer"
    autoload :CommentableFiction, "decidim/fictions/commentable_fiction"
    autoload :CommentableCollaborativeDraft, "decidim/fictions/commentable_collaborative_draft"
    autoload :MarkdownToFictions, "decidim/fictions/markdown_to_fictions"
    autoload :ParticipatoryTextSection, "decidim/fictions/participatory_text_section"
    autoload :DocToMarkdown, "decidim/fictions/doc_to_markdown"
    autoload :OdtToMarkdown, "decidim/fictions/odt_to_markdown"
    autoload :Valuatable, "decidim/fictions/valuatable"

    include ActiveSupport::Configurable

    # Public Setting that defines the similarity minimum value to consider two
    # fictions similar. Defaults to 0.25.
    config_accessor :similarity_threshold do
      0.25
    end

    # Public Setting that defines how many similar fictions will be shown.
    # Defaults to 10.
    config_accessor :similarity_limit do
      10
    end

    # Public Setting that defines how many fictions will be shown in the
    # participatory_space_highlighted_elements view hook
    config_accessor :participatory_space_highlighted_fictions_limit do
      4
    end

    # Public Setting that defines how many fictions will be shown in the
    # process_group_highlighted_elements view hook
    config_accessor :process_group_highlighted_fictions_limit do
      3
    end
  end

  module ContentParsers
    autoload :FictionParser, "decidim/content_parsers/fiction_parser"
  end

  module ContentRenderers
    autoload :FictionRenderer, "decidim/content_renderers/fiction_renderer"
  end
end
