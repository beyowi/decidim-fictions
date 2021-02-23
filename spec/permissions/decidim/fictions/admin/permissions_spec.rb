# frozen_string_literal: true

require "spec_helper"

describe Decidim::Fictions::Admin::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:user) { build :user, :admin }
  let(:current_component) { create(:fiction_component) }
  let(:fiction) { nil }
  let(:extra_context) { {} }
  let(:context) do
    {
      fiction: fiction,
      current_component: current_component,
      current_settings: current_settings,
      component_settings: component_settings
    }.merge(extra_context)
  end
  let(:component_settings) do
    double(
      official_fictions_enabled: official_fictions_enabled?,
      fiction_answering_enabled: component_settings_fiction_answering_enabled?,
      participatory_texts_enabled?: component_settings_participatory_texts_enabled?
    )
  end
  let(:current_settings) do
    double(
      creation_enabled?: creation_enabled?,
      fiction_answering_enabled: current_settings_fiction_answering_enabled?,
      publish_answers_immediately: current_settings_publish_answers_immediately?
    )
  end
  let(:creation_enabled?) { true }
  let(:official_fictions_enabled?) { true }
  let(:component_settings_fiction_answering_enabled?) { true }
  let(:component_settings_participatory_texts_enabled?) { true }
  let(:current_settings_fiction_answering_enabled?) { true }
  let(:current_settings_publish_answers_immediately?) { true }
  let(:permission_action) { Decidim::PermissionAction.new(action) }

  shared_examples "can create fiction notes" do
    describe "fiction note creation" do
      let(:action) do
        { scope: :admin, action: :create, subject: :fiction_note }
      end

      context "when the space allows it" do
        it { is_expected.to eq true }
      end
    end
  end

  shared_examples "can answer fictions" do
    describe "fiction answering" do
      let(:action) do
        { scope: :admin, action: :create, subject: :fiction_answer }
      end

      context "when everything is OK" do
        it { is_expected.to eq true }
      end

      context "when answering is disabled in the step level" do
        let(:current_settings_fiction_answering_enabled?) { false }

        it { is_expected.to eq false }
      end

      context "when answering is disabled in the component level" do
        let(:component_settings_fiction_answering_enabled?) { false }

        it { is_expected.to eq false }
      end
    end
  end

  shared_examples "can export fictions" do
    describe "export fictions" do
      let(:action) do
        { scope: :admin, action: :export, subject: :fictions }
      end

      context "when everything is OK" do
        it { is_expected.to eq true }
      end
    end
  end

  context "when user is a valuator" do
    let(:organization) { space.organization }
    let(:space) { current_component.participatory_space }
    let!(:valuator_role) { create :participatory_process_user_role, user: user, role: :valuator, participatory_process: space }
    let!(:user) { create :user, organization: organization }

    context "and can valuate the current fiction" do
      let(:fiction) { create :fiction, component: current_component }
      let!(:assignment) { create :valuation_assignment, fiction: fiction, valuator_role: valuator_role }

      it_behaves_like "can create fiction notes"
      it_behaves_like "can answer fictions"
      it_behaves_like "can export fictions"
    end

    context "when current user is the valuator" do
      describe "unassign fictions from themselves" do
        let(:action) do
          { scope: :admin, action: :unassign_from_valuator, subject: :fictions }
        end
        let(:extra_context) { { valuator: user } }

        it { is_expected.to eq true }
      end
    end
  end

  it_behaves_like "can create fiction notes"
  it_behaves_like "can answer fictions"
  it_behaves_like "can export fictions"

  describe "fiction creation" do
    let(:action) do
      { scope: :admin, action: :create, subject: :fiction }
    end

    context "when everything is OK" do
      it { is_expected.to eq true }
    end

    context "when creation is disabled" do
      let(:creation_enabled?) { false }

      it { is_expected.to eq false }
    end

    context "when official fictions are disabled" do
      let(:official_fictions_enabled?) { false }

      it { is_expected.to eq false }
    end
  end

  describe "fiction edition" do
    let(:action) do
      { scope: :admin, action: :edit, subject: :fiction }
    end

    context "when the fiction is not official" do
      let(:fiction) { create :fiction, component: current_component }

      it_behaves_like "permission is not set"
    end

    context "when the fiction is official" do
      let(:fiction) { create :fiction, :official, component: current_component }

      context "when everything is OK" do
        it { is_expected.to eq true }
      end

      context "when it has some votes" do
        before do
          create :fiction_vote, fiction: fiction
        end

        it_behaves_like "permission is not set"
      end
    end
  end

  describe "update fiction category" do
    let(:action) do
      { scope: :admin, action: :update, subject: :fiction_category }
    end

    it { is_expected.to eq true }
  end

  describe "import fictions from another component" do
    let(:action) do
      { scope: :admin, action: :import, subject: :fictions }
    end

    it { is_expected.to eq true }
  end

  describe "split fictions" do
    let(:action) do
      { scope: :admin, action: :split, subject: :fictions }
    end

    it { is_expected.to eq true }
  end

  describe "merge fictions" do
    let(:action) do
      { scope: :admin, action: :merge, subject: :fictions }
    end

    it { is_expected.to eq true }
  end

  describe "fiction answers publishing" do
    let(:user) { create(:user) }
    let(:action) do
      { scope: :admin, action: :publish_answers, subject: :fictions }
    end

    it { is_expected.to eq false }

    context "when user is an admin" do
      let(:user) { create(:user, :admin) }

      it { is_expected.to eq true }
    end
  end

  describe "assign fictions to a valuator" do
    let(:action) do
      { scope: :admin, action: :assign_to_valuator, subject: :fictions }
    end

    it { is_expected.to eq true }
  end

  describe "unassign fictions from a valuator" do
    let(:action) do
      { scope: :admin, action: :unassign_from_valuator, subject: :fictions }
    end

    it { is_expected.to eq true }
  end

  describe "manage participatory texts" do
    let(:action) do
      { scope: :admin, action: :manage, subject: :participatory_texts }
    end

    it { is_expected.to eq true }
  end
end
