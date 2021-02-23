# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic when an admin creates a private note fiction.
      class CreateFictionNote < Rectify::Command
        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # fiction - the fiction to relate.
        def initialize(form, fiction)
          @form = form
          @fiction = fiction
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the note fiction.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          create_fiction_note
          notify_admins_and_valuators

          broadcast(:ok, fiction_note)
        end

        private

        attr_reader :form, :fiction_note, :fiction

        def create_fiction_note
          @fiction_note = Decidim.traceability.create!(
            FictionNote,
            form.current_user,
            {
              body: form.body,
              fiction: fiction,
              author: form.current_user
            },
            resource: {
              title: fiction.title
            }
          )
        end

        def notify_admins_and_valuators
          affected_users = Decidim::User.org_admins_except_me(form.current_user).all
          affected_users += Decidim::Fictions::ValuationAssignment.includes(valuator_role: :user).where.not(id: form.current_user.id).where(fiction: fiction).map(&:valuator)

          data = {
            event: "decidim.events.fictions.admin.fiction_note_created",
            event_class: Decidim::Fictions::Admin::FictionNoteCreatedEvent,
            resource: fiction,
            affected_users: affected_users
          }

          Decidim::EventsManager.publish(data)
        end
      end
    end
  end
end
