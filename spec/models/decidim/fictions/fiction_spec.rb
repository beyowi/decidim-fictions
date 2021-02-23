# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe Fiction do
      subject { fiction }

      let(:component) { build :fiction_component }
      let(:organization) { component.participatory_space.organization }
      let(:fiction) { create(:fiction, component: component) }
      let(:coauthorable) { fiction }

      include_examples "coauthorable"
      include_examples "has component"
      include_examples "has scope"
      include_examples "has category"
      include_examples "has reference"
      include_examples "reportable"
      include_examples "resourceable"

      it { is_expected.to be_valid }
      it { is_expected.to be_versioned }

      describe "newsletter participants" do
        subject { Decidim::Fictions::Fiction.newsletter_participant_ids(fiction.component) }

        let!(:component_out_of_newsletter) { create(:fiction_component, organization: organization) }
        let!(:resource_out_of_newsletter) { create(:fiction, component: component_out_of_newsletter) }
        let!(:resource_in_newsletter) { create(:fiction, component: fiction.component) }
        let(:author_ids) { fiction.notifiable_identities.pluck(:id) + resource_in_newsletter.notifiable_identities.pluck(:id) }

        include_examples "counts commentators as newsletter participants"
      end

      it "has a votes association returning fiction votes" do
        expect(subject.votes.count).to eq(0)
      end

      describe "#voted_by?" do
        let(:user) { create(:user, organization: subject.organization) }

        it "returns false if the fiction is not voted by the given user" do
          expect(subject).not_to be_voted_by(user)
        end

        it "returns true if the fiction is not voted by the given user" do
          create(:fiction_vote, fiction: subject, author: user)
          expect(subject).to be_voted_by(user)
        end
      end

      describe "#endorsed_by?" do
        let(:user) { create(:user, organization: subject.organization) }

        context "with User endorsement" do
          it "returns false if the fiction is not endorsed by the given user" do
            expect(subject).not_to be_endorsed_by(user)
          end

          it "returns true if the fiction is not endorsed by the given user" do
            create(:endorsement, resource: subject, author: user)
            expect(subject).to be_endorsed_by(user)
          end
        end

        context "with Organization endorsement" do
          let!(:user_group) { create(:user_group, verified_at: Time.current, organization: user.organization) }
          let!(:membership) { create(:user_group_membership, user: user, user_group: user_group) }

          before { user_group.reload }

          it "returns false if the fiction is not endorsed by the given organization" do
            expect(subject).not_to be_endorsed_by(user, user_group)
          end

          it "returns true if the fiction is not endorsed by the given organization" do
            create(:endorsement, resource: subject, author: user, user_group: user_group)
            expect(subject).to be_endorsed_by(user, user_group)
          end
        end
      end

      context "when it has been accepted" do
        let(:fiction) { build(:fiction, :accepted) }

        it { is_expected.to be_answered }
        it { is_expected.to be_published_state }
        it { is_expected.to be_accepted }
      end

      context "when it has been rejected" do
        let(:fiction) { build(:fiction, :rejected) }

        it { is_expected.to be_answered }
        it { is_expected.to be_published_state }
        it { is_expected.to be_rejected }
      end

      describe "#users_to_notify_on_comment_created" do
        let!(:follows) { create_list(:follow, 3, followable: subject) }
        let(:followers) { follows.map(&:user) }
        let(:participatory_space) { subject.component.participatory_space }
        let(:organization) { participatory_space.organization }
        let!(:participatory_process_admin) do
          create(:process_admin, participatory_process: participatory_space)
        end

        context "when the fiction is official" do
          let(:fiction) { build(:fiction, :official) }

          it "returns the followers and the component's participatory space admins" do
            expect(subject.users_to_notify_on_comment_created).to match_array(followers.concat([participatory_process_admin]))
          end
        end

        context "when the fiction is not official" do
          it "returns the followers and the author" do
            expect(subject.users_to_notify_on_comment_created).to match_array(followers.concat([fiction.creator.author]))
          end
        end
      end

      describe "#maximum_votes" do
        let(:maximum_votes) { 10 }

        context "when the component's settings are set to an integer bigger than 0" do
          before do
            component[:settings]["global"] = { threshold_per_fiction: 10 }
            component.save!
          end

          it "returns the maximum amount of votes for this fiction" do
            expect(fiction.maximum_votes).to eq(10)
          end
        end

        context "when the component's settings are set to 0" do
          before do
            component[:settings]["global"] = { threshold_per_fiction: 0 }
            component.save!
          end

          it "returns nil" do
            expect(fiction.maximum_votes).to be_nil
          end
        end
      end

      describe "#editable_by?" do
        let(:author) { create(:user, organization: organization) }

        context "when user is author" do
          let(:fiction) { create :fiction, component: component, users: [author], updated_at: Time.current }

          it { is_expected.to be_editable_by(author) }

          context "when the fiction has been linked to another one" do
            let(:fiction) { create :fiction, component: component, users: [author], updated_at: Time.current }
            let(:original_fiction) do
              original_component = create(:fiction_component, organization: organization, participatory_space: component.participatory_space)
              create(:fiction, component: original_component)
            end

            before do
              fiction.link_resources([original_fiction], "copied_from_component")
            end

            it { is_expected.not_to be_editable_by(author) }
          end
        end

        context "when fiction is from user group and user is admin" do
          let(:user_group) { create :user_group, :verified, users: [author], organization: author.organization }
          let(:fiction) { create :fiction, component: component, updated_at: Time.current, users: [author], user_groups: [user_group] }

          it { is_expected.to be_editable_by(author) }
        end

        context "when user is not the author" do
          let(:fiction) { create :fiction, component: component, updated_at: Time.current }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when fiction is answered" do
          let(:fiction) { build :fiction, :with_answer, component: component, updated_at: Time.current, users: [author] }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when fiction editing time has run out" do
          let(:fiction) { build :fiction, updated_at: 10.minutes.ago, component: component, users: [author] }

          it { is_expected.not_to be_editable_by(author) }
        end
      end

      describe "#withdrawn?" do
        context "when fiction is withdrawn" do
          let(:fiction) { build :fiction, :withdrawn }

          it { is_expected.to be_withdrawn }
        end

        context "when fiction is not withdrawn" do
          let(:fiction) { build :fiction }

          it { is_expected.not_to be_withdrawn }
        end
      end

      describe "#withdrawable_by" do
        let(:author) { create(:user, organization: organization) }

        context "when user is author" do
          let(:fiction) { create :fiction, component: component, users: [author], created_at: Time.current }

          it { is_expected.to be_withdrawable_by(author) }
        end

        context "when user is admin" do
          let(:admin) { build(:user, :admin, organization: organization) }
          let(:fiction) { build :fiction, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(admin) }
        end

        context "when user is not the author" do
          let(:someone_else) { build(:user, organization: organization) }
          let(:fiction) { build :fiction, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(someone_else) }
        end

        context "when fiction is already withdrawn" do
          let(:fiction) { build :fiction, :withdrawn, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(author) }
        end

        context "when the fiction has been linked to another one" do
          let(:fiction) { create :fiction, component: component, users: [author], created_at: Time.current }
          let(:original_fiction) do
            original_component = create(:fiction_component, organization: organization, participatory_space: component.participatory_space)
            create(:fiction, component: original_component)
          end

          before do
            fiction.link_resources([original_fiction], "copied_from_component")
          end

          it { is_expected.not_to be_withdrawable_by(author) }
        end
      end

      context "when answer is not published" do
        let(:fiction) { create(:fiction, :accepted_not_published, component: component) }

        it "has accepted as the internal state" do
          expect(fiction.internal_state).to eq("accepted")
        end

        it "has not_answered as public state" do
          expect(fiction.state).to be_nil
        end

        it { is_expected.not_to be_accepted }
        it { is_expected.to be_answered }
        it { is_expected.not_to be_published_state }
      end

      describe "#with_valuation_assigned_to" do
        let(:user) { create :user, organization: organization }
        let(:space) { component.participatory_space }
        let!(:valuator_role) { create :participatory_process_user_role, role: :valuator, user: user, participatory_process: space }
        let(:assigned_fiction) { create :fiction, component: component }
        let!(:assignment) { create :valuation_assignment, fiction: assigned_fiction, valuator_role: valuator_role }

        it "only returns the assigned fictions for the given space" do
          results = described_class.with_valuation_assigned_to(user, space)

          expect(results).to eq([assigned_fiction])
        end
      end
    end
  end
end
