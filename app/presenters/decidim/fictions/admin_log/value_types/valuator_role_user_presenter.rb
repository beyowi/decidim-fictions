# frozen_string_literal: true

module Decidim
  module Fictions
    module AdminLog
      module ValueTypes
        class ValuatorRoleUserPresenter < Decidim::Log::ValueTypes::DefaultPresenter
          def present
            return unless value

            role = Decidim::Fictions::ValuationAssignment.find_by(valuator_role_id: value).valuator_role
            user = role.user
            user.try(:name)
          end
        end
      end
    end
  end
end
