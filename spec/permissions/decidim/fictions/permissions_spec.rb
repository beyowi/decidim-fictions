# frozen_string_literal: true

require "spec_helper"

describe Decidim::Fictions::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:user) { fiction.creator_author }
  let(:context) do
    {
      current_component: fiction_component,
      current_settings: current_settings,
      fiction: fiction,
      component_settings: component_settings
    }
  end
  let(:fiction_component) { create :fiction_component }
  let(:fiction) { create :fiction, component: fiction_component }
  let(:component_settings) do
    double(vote_limit: 2)
  end
  let(:current_settings) do
    double(settings.merge(extra_settings))
  end
  let(:settings) do
    {
      creation_enabled?: false
    }
  end
  let(:extra_settings) { {} }
  let(:permission_action) { Decidim::PermissionAction.new(action) }

  context "when scope is admin" do
    let(:action) do
      { scope: :admin, action: :vote, subject: :fiction }
    end

    it_behaves_like "delegates permissions to", Decidim::Fictions::Admin::Permissions
  end

  context "when scope is not public" do
    let(:action) do
      { scope: :foo, action: :vote, subject: :fiction }
    end

    it_behaves_like "permission is not set"
  end

  context "when subject is not a fiction" do
    let(:action) do
      { scope: :public, action: :vote, subject: :foo }
    end

    it_behaves_like "permission is not set"
  end

  context "when creating a fiction" do
    let(:action) do
      { scope: :public, action: :create, subject: :fiction }
    end

    context "when creation is disabled" do
      let(:extra_settings) { { creation_enabled?: false } }

      it { is_expected.to eq false }
    end

    context "when user is authorized" do
      let(:extra_settings) { { creation_enabled?: true } }

      it { is_expected.to eq true }
    end
  end

  context "when editing a fiction" do
    let(:action) do
      { scope: :public, action: :edit, subject: :fiction }
    end

    before do
      allow(fiction).to receive(:editable_by?).with(user).and_return(editable)
    end

    context "when fiction is editable" do
      let(:editable) { true }

      it { is_expected.to eq true }
    end

    context "when fiction is not editable" do
      let(:editable) { false }

      it { is_expected.to eq false }
    end
  end

  context "when withdrawing a fiction" do
    let(:action) do
      { scope: :public, action: :withdraw, subject: :fiction }
    end

    context "when fiction author is the user trying to withdraw" do
      it { is_expected.to eq true }
    end

    context "when trying by another user" do
      let(:user) { build :user }

      it { is_expected.to eq false }
    end
  end

  describe "voting" do
    let(:action) do
      { scope: :public, action: :vote, subject: :fiction }
    end

    context "when voting is disabled" do
      let(:extra_settings) do
        {
          votes_enabled?: false,
          votes_blocked?: true
        }
      end

      it { is_expected.to eq false }
    end

    context "when votes are blocked" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: true
        }
      end

      it { is_expected.to eq false }
    end

    context "when the user has no more remaining votes" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: false
        }
      end

      before do
        fictions = create_list :fiction, 2, component: fiction_component
        create :fiction_vote, author: user, fiction: fictions[0]
        create :fiction_vote, author: user, fiction: fictions[1]
      end

      it { is_expected.to eq false }
    end

    context "when the user is authorized" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: false
        }
      end

      it { is_expected.to eq true }
    end
  end

  describe "unvoting" do
    let(:action) do
      { scope: :public, action: :unvote, subject: :fiction }
    end

    context "when voting is disabled" do
      let(:extra_settings) do
        {
          votes_enabled?: false,
          votes_blocked?: true
        }
      end

      it { is_expected.to eq false }
    end

    context "when votes are blocked" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: true
        }
      end

      it { is_expected.to eq false }
    end

    context "when the user is authorized" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: false
        }
      end

      it { is_expected.to eq true }
    end
  end

  describe "amend" do
    let(:action) do
      { scope: :public, action: :amend, subject: :fiction }
    end

    context "when amend is disabled" do
      let(:extra_settings) do
        {
          amendments_enabled?: false
        }
      end

      it { is_expected.to eq false }
    end

    context "when the user is authorized" do
      let(:extra_settings) do
        {
          amendments_enabled?: true
        }
      end

      it { is_expected.to eq true }
    end
  end
end
