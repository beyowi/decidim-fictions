# frozen_string_literal: true

require "open-uri"

module Decidim
  module Fictions
    # A factory class to ensure we always create Fictions the same way since it involves some logic.
    module FictionBuilder
      # Public: Creates a new Fiction.
      #
      # attributes        - The Hash of attributes to create the Fiction with.
      # author            - An Authorable the will be the first coauthor of the Fiction.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the fiction in the traceability logs.
      #
      # Returns a Fiction.
      def create(attributes:, author:, action_user:, user_group_author: nil)
        Decidim.traceability.perform_action!(:create, Fiction, action_user, visibility: "all") do
          fiction = Fiction.new(attributes)
          fiction.add_coauthor(author, user_group: user_group_author)
          fiction.save!
          fiction
        end
      end

      module_function :create

      # Public: Creates a new Fiction with the authors of the `original_fiction`.
      #
      # attributes - The Hash of attributes to create the Fiction with.
      # action_user - The User to be used as the user who is creating the fiction in the traceability logs.
      # original_fiction - The fiction from which authors will be copied.
      #
      # Returns a Fiction.
      def create_with_authors(attributes:, action_user:, original_fiction:)
        Decidim.traceability.perform_action!(:create, Fiction, action_user, visibility: "all") do
          fiction = Fiction.new(attributes)
          original_fiction.coauthorships.each do |coauthorship|
            fiction.add_coauthor(coauthorship.author, user_group: coauthorship.user_group)
          end
          fiction.save!
          fiction
        end
      end

      module_function :create_with_authors

      # Public: Creates a new Fiction by copying the attributes from another one.
      #
      # original_fiction - The Fiction to be used as base to create the new one.
      # author            - An Authorable the will be the first coauthor of the Fiction.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the fiction in the traceability logs.
      # extra_attributes  - A Hash of attributes to create the new fiction, will overwrite the original ones.
      # skip_link         - Whether to skip linking the two fictions or not (default false).
      #
      # Returns a Fiction
      #
      # rubocop:disable Metrics/ParameterLists
      def copy(original_fiction, author:, action_user:, user_group_author: nil, extra_attributes: {}, skip_link: false)
        origin_attributes = original_fiction.attributes.except(
          "id",
          "created_at",
          "updated_at",
          "state",
          "answer",
          "answered_at",
          "decidim_component_id",
          "reference",
          "fiction_votes_count",
          "endorsements_count",
          "fiction_notes_count"
        ).merge(
          "category" => original_fiction.category
        ).merge(
          extra_attributes
        )

        fiction = if author.nil?
                     create_with_authors(
                       attributes: origin_attributes,
                       original_fiction: original_fiction,
                       action_user: action_user
                     )
                   else
                     create(
                       attributes: origin_attributes,
                       author: author,
                       user_group_author: user_group_author,
                       action_user: action_user
                     )
                   end

        fiction.link_resources(original_fiction, "copied_from_component") unless skip_link
        copy_attachments(original_fiction, fiction)

        fiction
      end
      # rubocop:enable Metrics/ParameterLists

      module_function :copy

      def copy_attachments(original_fiction, fiction)
        original_fiction.attachments.each do |attachment|
          new_attachment = Decidim::Attachment.new(attachment.attributes.slice("content_type", "description", "file", "file_size", "title", "weight"))
          new_attachment.attached_to = fiction

          if File.exist?(attachment.file.file.path)
            new_attachment.file = File.open(attachment.file.file.path)
          else
            new_attachment.remote_file_url = attachment.url
          end

          new_attachment.save!
        rescue Errno::ENOENT, OpenURI::HTTPError => e
          Rails.logger.warn("[ERROR] Couldn't copy attachment from fiction #{original_fiction.id} when copying to component due to #{e.message}")
        end
      end

      module_function :copy_attachments
    end
  end
end
