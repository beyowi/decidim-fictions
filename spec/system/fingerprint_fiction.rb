# frozen_string_literal: true

require "spec_helper"

describe "Fingerprint fiction", type: :system do
  let(:manifest_name) { "fictions" }

  let!(:fingerprintable) do
    create(:fiction, component: component)
  end

  include_examples "fingerprint"
end
