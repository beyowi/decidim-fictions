# frozen_string_literal: true

module Decidim
  module Fictions
    module AdminLog
      module ValueTypes
        class FictionStatePresenter < Decidim::Log::ValueTypes::DefaultPresenter
          def present
            return unless value

            h.t(value, scope: "decidim.fictions.admin.fiction_answers.edit", default: value)
          end
        end
      end
    end
  end
end
