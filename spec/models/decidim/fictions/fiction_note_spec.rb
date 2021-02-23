# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe FictionNote do
      subject { fiction_note }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "fictions") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, :admin, organization: organization) }
      let!(:fiction) { create(:fiction, component: component, users: [author]) }
      let!(:fiction_note) { build(:fiction_note, fiction: fiction, author: author) }

      it { is_expected.to be_valid }
      it { is_expected.to be_versioned }

      it "has an associated author" do
        expect(fiction_note.author).to be_a(Decidim::User)
      end

      it "has an associated fiction" do
        expect(fiction_note.fiction).to be_a(Decidim::Fictions::Fiction)
      end
    end
  end
end
