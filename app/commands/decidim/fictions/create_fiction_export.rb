# frozen_string_literal: true

module Decidim
  module Fictions
    # A command with all the business logic when a user creates a new fiction.
    class CreateFictionExport < Rectify::Command
      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      def initialize(participatory_process)
        @participatory_process = participatory_process
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the fiction.
      # - :invalid if the fiction wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if participatory_process.invalid?

        create_fiction_export
        broadcast(:ok, export)
      end

      private

      attr_reader :participatory_process

      def create_fiction_export
        FictionsExporterJob.perform_later(participatory_process)
      end
    end
  end
end
