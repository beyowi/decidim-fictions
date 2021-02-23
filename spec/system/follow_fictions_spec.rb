# frozen_string_literal: true

require "spec_helper"

describe "Follow fictions", type: :system do
  let(:manifest_name) { "fictions" }

  let!(:followable) do
    create(:fiction, component: component)
  end

  include_examples "follows"
end
