# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic when a user updates a fiction.
      class UpdateFiction < Rectify::Command
        include ::Decidim::AttachmentMethods
        include GalleryMethods
        include HashtagsMethods

        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # fiction - the fiction to update.
        def initialize(form, fiction)
          @form = form
          @fiction = fiction
          @attached_to = fiction
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the fiction.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          if process_attachments?
            @fiction.attachments.destroy_all

            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          if process_gallery?
            build_gallery
            return broadcast(:invalid) if gallery_invalid?
          end

          transaction do
            update_fiction
            update_fiction_author
            create_attachment if process_attachments?
            create_gallery if process_gallery?
            photo_cleanup!
          end

          broadcast(:ok, fiction)
        end

        private

        attr_reader :form, :fiction, :attachment, :gallery

        def update_fiction
          Decidim.traceability.update!(
            fiction,
            form.current_user,
            title: title_with_hashtags,
            body: body_with_hashtags,
            category: form.category,
            scope: form.scope,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            created_in_meeting: form.created_in_meeting
          )
        end

        def update_fiction_author
          fiction.coauthorships.clear
          fiction.add_coauthor(form.author)
          fiction.save!
          fiction
        end
      end
    end
  end
end
