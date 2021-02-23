# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe FictionVote do
      subject { fiction_vote }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "fictions") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, organization: organization) }
      let!(:fiction) { create(:fiction, component: component, users: [author]) }
      let!(:fiction_vote) { build(:fiction_vote, fiction: fiction, author: author) }

      it "is valid" do
        expect(fiction_vote).to be_valid
      end

      it "has an associated author" do
        expect(fiction_vote.author).to be_a(Decidim::User)
      end

      it "has an associated fiction" do
        expect(fiction_vote.fiction).to be_a(Decidim::Fictions::Fiction)
      end

      it "validates uniqueness for author and fiction combination" do
        fiction_vote.save!
        expect do
          create(:fiction_vote, fiction: fiction, author: author)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      context "when no author" do
        before do
          fiction_vote.author = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when no fiction" do
        before do
          fiction_vote.fiction = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when fiction and author have different organization" do
        let(:other_author) { create(:user) }
        let(:other_fiction) { create(:fiction) }

        it "is invalid" do
          fiction_vote = build(:fiction_vote, fiction: other_fiction, author: other_author)
          expect(fiction_vote).to be_invalid
        end
      end

      context "when fiction is rejected" do
        let!(:fiction) { create(:fiction, :rejected, component: component, users: [author]) }

        it { is_expected.to be_invalid }
      end
    end
  end
end
