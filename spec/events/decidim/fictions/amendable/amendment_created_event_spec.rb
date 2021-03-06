# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe AmendmentCreatedEvent do
      let!(:component) { create(:fiction_component) }
      let!(:amendable) { create(:fiction, component: component, title: "My super fiction") }
      let!(:emendation) { create(:fiction, component: component, title: "My super emendation") }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation }

      include_examples "amendment created event"
    end
  end
end
