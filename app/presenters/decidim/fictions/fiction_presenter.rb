# frozen_string_literal: true

module Decidim
  module Fictions
    #
    # Decorator for fictions
    #
    class FictionPresenter < SimpleDelegator
      include Rails.application.routes.mounted_helpers
      include ActionView::Helpers::UrlHelper
      include Decidim::SanitizeHelper

      def author
        @author ||= if official?
                      Decidim::Fictions::OfficialAuthorPresenter.new
                    else
                      coauthorship = coauthorships.includes(:author, :user_group).first
                      coauthorship.user_group&.presenter || coauthorship.author.presenter
                    end
      end

      def fiction
        __getobj__
      end

      def fiction_path
        Decidim::ResourceLocatorPresenter.new(fiction).path
      end

      def display_mention
        link_to title, fiction_path
      end

      # Render the fiction title
      #
      # links - should render hashtags as links?
      # extras - should include extra hashtags?
      #
      # Returns a String.
      def title(links: false, extras: true, html_escape: false)
        text = fiction.title
        text = decidim_html_escape(text) if html_escape

        renderer = Decidim::ContentRenderers::HashtagRenderer.new(text)
        renderer.render(links: links, extras: extras).html_safe
      end

      def id_and_title(links: false, extras: true, html_escape: false)
        "##{fiction.id} - #{title(links: links, extras: extras, html_escape: html_escape)}"
      end

      def body(links: false, extras: true, strip_tags: false)
        text = fiction.body

        if strip_tags
          text = text.gsub(%r{<\/p>}, "\n\n")
          text = strip_tags(text)
        end

        renderer = Decidim::ContentRenderers::HashtagRenderer.new(text)
        text = renderer.render(links: links, extras: extras).html_safe

        text = Decidim::ContentRenderers::LinkRenderer.new(text).render if links
        text
      end

      # Returns the fiction versions, hiding not published answers
      #
      # Returns an Array.
      def versions
        version_state_published = false
        pending_state_change = nil

        fiction.versions.map do |version|
          state_published_change = version.changeset["state_published_at"]
          version_state_published = state_published_change.last.present? if state_published_change

          if version_state_published
            version.changeset["state"] = pending_state_change if pending_state_change
            pending_state_change = nil
          elsif version.changeset["state"]
            pending_state_change = version.changeset.delete("state")
          end

          next if version.event == "update" && Decidim::Fictions::DiffRenderer.new(version).diff.empty?

          version
        end.compact
      end

      delegate :count, to: :versions, prefix: true

      def resource_manifest
        fiction.class.resource_manifest
      end
    end
  end
end
