# frozen_string_literal: true

module Decidim
  module Fictions
    # A command with all the business logic when a user updates a fiction.
    class UpdateFiction < Rectify::Command
      include ::Decidim::AttachmentMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # fiction - the fiction to update.
      def initialize(form, current_user, fiction)
        @form = form
        @current_user = current_user
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
        return broadcast(:invalid) unless fiction.editable_by?(current_user)
        return broadcast(:invalid) if fiction_limit_reached?

        if process_attachments?
          @fiction.attachments.destroy_all

          build_attachment
          return broadcast(:invalid) if attachment_invalid?
        end

        transaction do
          if @fiction.draft?
            update_draft
          else
            update_fiction
          end
          create_attachment if process_attachments?
        end

        broadcast(:ok, fiction)
      end

      private

      attr_reader :form, :fiction, :current_user, :attachment

      # Prevent PaperTrail from creating an additional version
      # in the fiction multi-step creation process (step 3: complete)
      #
      # A first version will be created in step 4: publish
      # for diff rendering in the fiction control version
      def update_draft
        PaperTrail.request(enabled: false) do
          @fiction.update(attributes)
          @fiction.coauthorships.clear
          @fiction.add_coauthor(current_user, user_group: user_group)
        end
      end

      def update_fiction
        @fiction = Decidim.traceability.update!(
          @fiction,
          current_user,
          attributes,
          visibility: "public-only"
        )
        @fiction.coauthorships.clear
        @fiction.add_coauthor(current_user, user_group: user_group)
      end

      def attributes
        {
          title: title_with_hashtags,
          body: body_with_hashtags,
          category: form.category,
          scope: form.scope,
          address: form.address,
          latitude: form.latitude,
          longitude: form.longitude
        }
      end

      def fiction_limit_reached?
        fiction_limit = form.current_component.settings.fiction_limit

        return false if fiction_limit.zero?

        if user_group
          user_group_fictions.count >= fiction_limit
        else
          current_user_fictions.count >= fiction_limit
        end
      end

      def user_group
        @user_group ||= Decidim::UserGroup.find_by(organization: organization, id: form.user_group_id)
      end

      def organization
        @organization ||= current_user.organization
      end

      def current_user_fictions
        Fiction.from_author(current_user).where(component: form.current_component).published.where.not(id: fiction.id).except_withdrawn
      end

      def user_group_fictions
        Fiction.from_user_group(user_group).where(component: form.current_component).published.where.not(id: fiction.id).except_withdrawn
      end
    end
  end
end
