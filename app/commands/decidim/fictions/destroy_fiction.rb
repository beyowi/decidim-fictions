# frozen_string_literal: true

module Decidim
  module Fictions
    # A command with all the business logic when a user destroys a draft fiction.
    class DestroyFiction < Rectify::Command
      # Public: Initializes the command.
      #
      # fiction     - The fiction to destroy.
      # current_user - The current user.
      def initialize(fiction, current_user)
        @fiction = fiction
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the fiction is deleted.
      # - :invalid if the fiction is not a draft.
      # - :invalid if the fiction's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @fiction.draft?
        return broadcast(:invalid) unless @fiction.authored_by?(@current_user)

        @fiction.destroy!

        broadcast(:ok, @fiction)
      end
    end
  end
end
