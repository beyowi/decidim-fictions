# frozen_string_literal: true

require "spec_helper"

describe "Fictions component" do # rubocop:disable RSpec/DescribeClass
  let!(:component) { create(:fiction_component) }
  let(:organization) { component.organization }
  let!(:current_user) { create(:user, :admin, organization: organization) }

  describe "on destroy" do
    context "when there are no fictions for the component" do
      it "destroys the component" do
        expect do
          Decidim::Admin::DestroyComponent.call(component, current_user)
        end.to change { Decidim::Component.count }.by(-1)

        expect(component).to be_destroyed
      end
    end

    context "when there are fictions for the component" do
      before do
        create(:fiction, component: component)
      end

      it "raises an error" do
        expect do
          Decidim::Admin::DestroyComponent.call(component, current_user)
        end.to broadcast(:invalid)

        expect(component).not_to be_destroyed
      end
    end
  end

  describe "stats" do
    subject { current_stat[2] }

    let(:raw_stats) do
      Decidim.component_manifests.map do |component_manifest|
        component_manifest.stats.filter(name: stats_name).with_context(component).flat_map { |name, data| [component_manifest.name, name, data] }
      end
    end

    let(:stats) do
      raw_stats.select { |stat| stat[0] == :fictions }
    end

    let!(:fiction) { create :fiction }
    let(:component) { fiction.component }
    let!(:hidden_fiction) { create :fiction, component: component }
    let!(:draft_fiction) { create :fiction, :draft, component: component }
    let!(:withdrawn_fiction) { create :fiction, :withdrawn, component: component }
    let!(:moderation) { create :moderation, reportable: hidden_fiction, hidden_at: 1.day.ago }

    let(:current_stat) { stats.find { |stat| stat[1] == stats_name } }

    describe "fictions_count" do
      let(:stats_name) { :fictions_count }

      it "only counts published (except withdrawn) and not hidden fictions" do
        expect(Decidim::Fictions::Fiction.where(component: component).count).to eq 4
        expect(subject).to eq 1
      end
    end

    describe "fictions_accepted" do
      let!(:accepted_fiction) { create :fiction, :accepted, component: component }
      let!(:accepted_hidden_fiction) { create :fiction, :accepted, component: component }
      let!(:moderation) { create :moderation, reportable: accepted_hidden_fiction, hidden_at: 1.day.ago }
      let(:stats_name) { :fictions_accepted }

      it "only counts accepted and not hidden fictions" do
        expect(Decidim::Fictions::Fiction.where(component: component).count).to eq 6
        expect(subject).to eq 1
      end
    end

    describe "supports_count" do
      let(:stats_name) { :supports_count }

      before do
        create_list :fiction_vote, 2, fiction: fiction
        create_list :fiction_vote, 3, fiction: hidden_fiction
      end

      it "counts the votes from visible fictions" do
        expect(Decidim::Fictions::FictionVote.count).to eq 5
        expect(subject).to eq 2
      end
    end

    describe "endorsements_count" do
      let(:stats_name) { :endorsements_count }

      before do
        # rubocop:disable FactoryBot/CreateList
        2.times do
          create(:endorsement, resource: fiction, author: build(:user, organization: organization))
        end
        3.times do
          create(:endorsement, resource: hidden_fiction, author: build(:user, organization: organization))
        end
        # rubocop:enable FactoryBot/CreateList
      end

      it "counts the endorsements from visible fictions" do
        expect(Decidim::Endorsement.count).to eq 5
        expect(subject).to eq 2
      end
    end

    describe "comments_count" do
      let(:stats_name) { :comments_count }

      before do
        create_list :comment, 2, commentable: fiction
        create_list :comment, 3, commentable: hidden_fiction
      end

      it "counts the comments from visible fictions" do
        expect(Decidim::Comments::Comment.count).to eq 5
        expect(subject).to eq 2
      end
    end
  end

  describe "on edit", type: :system do
    let(:edit_component_path) do
      Decidim::EngineRouter.admin_proxy(component.participatory_space).edit_component_path(component.id)
    end

    before do
      switch_to_host(organization.host)
      login_as current_user, scope: :user
    end

    describe "participatory_texts_enabled" do
      let(:participatory_texts_enabled_container) { page.find(".participatory_texts_enabled_container") }

      before do
        visit edit_component_path
      end

      context "when there are no fictions for the component" do
        it "allows to check the setting" do
          expect(participatory_texts_enabled_container[:class]).not_to include("readonly")
          expect(page).not_to have_content("Cannot interact with this setting if there are existing fictions. Please, create a new `Fictions component` if you want to enable this feature or discard all imported fictions in the `Participatory Texts` menu if you want to disable it.")
        end

        it "changes the setting value after updating" do
          expect do # rubocop:disable Lint/AmbiguousBlockAssociation
            check "Participatory texts enabled"
            click_button "Update"
          end.to change { component.reload.settings.participatory_texts_enabled }
        end
      end

      context "when there are fictions for the component" do
        before do
          component.update(settings: { participatory_texts_enabled: true }) # Testing from true to false
          create(:fiction, component: component)
          visit edit_component_path
        end

        it "does NOT allow to check the setting" do
          expect(participatory_texts_enabled_container[:class]).to include("readonly")
          expect(page).to have_content("Cannot interact with this setting if there are existing fictions. Please, create a new `Fictions component` if you want to enable this feature or discard all imported fictions in the `Participatory Texts` menu if you want to disable it.")
        end

        it "does NOT change the setting value after updating" do
          expect do # rubocop:disable Lint/AmbiguousBlockAssociation
            click_button "Update"
          end.not_to change { component.reload.settings.participatory_texts_enabled }
        end
      end
    end

    describe "amendments settings" do
      let(:fields) do
        [
          "Amendments Wizard help text",
          "Amendments visibility",
          "Amendment creation enabled",
          "Amendment reaction enabled",
          "Amendment promotion enabled"
        ]
      end

      before do
        visit edit_component_path
      end

      it "doesn't show the amendments dependent settings" do
        fields.each do |field|
          expect(page).not_to have_content(field)
          expect(page).to have_css(".#{field.parameterize.underscore}_container", visible: :all)
        end
      end

      context "when amendments_enabled global setting is checked" do
        before do
          check "Amendments enabled"
        end

        it "shows the amendments dependent settings" do
          fields.each do |field|
            expect(page).to have_content(field)
            expect(page).to have_css(".#{field.parameterize.underscore}_container", visible: :visible)
          end
        end
      end
    end
  end

  describe "fictions exporter" do
    subject do
      component
        .manifest
        .export_manifests
        .find { |manifest| manifest.name == :fictions }
        .collection
        .call(component, user)
    end

    let!(:assigned_fiction) { create :fiction }
    let(:component) { assigned_fiction.component }
    let!(:unassigned_fiction) { create :fiction, component: component }
    let(:participatory_process) { component.participatory_space }
    let(:organization) { participatory_process.organization }

    context "when the user is a valuator" do
      let!(:user) { create :user, admin: false, organization: organization }
      let!(:valuator_role) { create :participatory_process_user_role, role: :valuator, user: user, participatory_process: participatory_process }

      before do
        create :valuation_assignment, fiction: assigned_fiction, valuator_role: valuator_role
      end

      it "only exports assigned fictions" do
        expect(subject).to eq([assigned_fiction])
      end
    end

    context "when the user is an admin" do
      let!(:user) { create :user, admin: true, organization: organization }

      it "exports all fictions from the component" do
        expect(subject).to match_array([unassigned_fiction, assigned_fiction])
      end
    end
  end
end
