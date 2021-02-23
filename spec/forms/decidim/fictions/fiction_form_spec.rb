# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe FictionForm do
      let(:params) do
        super.merge(
          user_group_id: user_group_id
        )
      end

      it_behaves_like "a fiction form", user_group_check: true
    end
  end
end
