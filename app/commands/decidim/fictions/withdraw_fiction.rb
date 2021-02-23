# frozen_string_literal: true

module Decidim
  module Fictions
    # A command with all the business logic when a user withdraws a new fiction.
    class WithdrawFiction < Rectify::Command
      # Public: Initializes the command.
      #
      # fiction     - The fiction to withdraw.
      # current_user - The current user.
      def initialize(fiction, current_user)
        @fiction = fiction
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the fiction.
      # - :has_supports if the fiction already has supports or does not belong to current user.
      #
      # Returns nothing.
      def call
        return broadcast(:has_supports) if @fiction.votes.any?

        transaction do
          change_fiction_state_to_withdrawn
          reject_emendations_if_any
        end

        broadcast(:ok, @fiction)
      end

      private

      def change_fiction_state_to_withdrawn
        @fiction.update state: "withdrawn"
      end

      def reject_emendations_if_any
        return if @fiction.emendations.empty?

        @fiction.emendations.each do |emendation|
          @form = form(Decidim::Amendable::RejectForm).from_params(id: emendation.amendment.id)
          result = Decidim::Amendable::Reject.call(@form)
          return result[:ok] if result[:ok]
        end
      end
    end
  end
end
