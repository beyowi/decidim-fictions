# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe FictionForm do
        it_behaves_like "a fiction form", skip_etiquette_validation: true
        it_behaves_like "a fiction form with meeting as author", skip_etiquette_validation: true
      end
    end
  end
end
