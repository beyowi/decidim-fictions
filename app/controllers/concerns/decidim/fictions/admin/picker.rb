# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Fictions
    module Admin
      module Picker
        extend ActiveSupport::Concern

        included do
          helper Decidim::Fictions::Admin::FictionsPickerHelper
        end

        def fictions_picker
          render :fictions_picker, layout: false
        end
      end
    end
  end
end
