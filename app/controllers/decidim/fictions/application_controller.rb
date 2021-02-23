# frozen_string_literal: true

module Decidim
  module Fictions
    # This controller is the abstract class from which all other controllers of
    # this engine inherit.
    #
    # Note that it inherits from `Decidim::Components::BaseController`, which
    # override its layout and provide all kinds of useful methods.
    class ApplicationController < Decidim::Components::BaseController
      helper Decidim::Messaging::ConversationHelper
      helper_method :fiction_limit_reached?

      def fiction_limit
        return nil if component_settings.fiction_limit.zero?

        component_settings.fiction_limit
      end

      def fiction_limit_reached?
        return false unless fiction_limit

        fictions.where(author: current_user).count >= fiction_limit
      end

      def fictions
        Fiction.where(component: current_component)
      end
    end
  end
end
