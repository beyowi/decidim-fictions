# frozen_string_literal: true

module Decidim
  module Fictions
    # A command with all the business logic when a user creates a new fiction.
    class CreateFiction < Rectify::Command
      include ::Decidim::AttachmentMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # coauthorships - The coauthorships of the fiction.
      def initialize(form, current_user, coauthorships = nil)
        @form = form
        @current_user = current_user
        @coauthorships = coauthorships
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the fiction.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        if fiction_limit_reached?
          form.errors.add(:base, I18n.t("decidim.fictions.new.limit_reached"))
          return broadcast(:invalid)
        end

        transaction do
          create_fiction
        end

        broadcast(:ok, fiction)
      end

      private

      attr_reader :form, :fiction, :attachment

      # Prevent PaperTrail from creating an additional version
      # in the fiction multi-step creation process (step 1: create)
      #
      # A first version will be created in step 4: publish
      # for diff rendering in the fiction version control
      def create_fiction
        PaperTrail.request(enabled: false) do
          @fiction = Decidim.traceability.perform_action!(
            :create,
            Decidim::Fictions::Fiction,
            @current_user,
            visibility: "public-only"
          ) do
            fiction = Fiction.new(
              title: title_with_hashtags,
              body: body_with_hashtags,
              component: form.component
            )
            fiction.add_coauthor(@current_user, user_group: user_group)
            fiction.save!
            fiction
          end
        end
      end

      def fiction_limit_reached?
        return false if @coauthorships.present?

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
        @organization ||= @current_user.organization
      end

      def current_user_fictions
        Fiction.from_author(@current_user).where(component: form.current_component).except_withdrawn
      end

      def user_group_fictions
        Fiction.from_user_group(@user_group).where(component: form.current_component).except_withdrawn
      end
    end
  end
end
