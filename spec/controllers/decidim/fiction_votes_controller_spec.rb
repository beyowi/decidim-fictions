# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe FictionVotesController, type: :controller do
      routes { Decidim::Fictions::Engine.routes }

      let(:fiction) { create(:fiction, component: component) }
      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:params) do
        {
          fiction_id: fiction.id,
          component_id: component.id
        }
      end

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_participatory_space"] = component.participatory_space
        request.env["decidim.current_component"] = component
        sign_in user
      end

      describe "POST create" do
        context "with votes enabled" do
          let(:component) do
            create(:fiction_component, :with_votes_enabled)
          end

          it "allows voting" do
            expect do
              post :create, format: :js, params: params
            end.to change(FictionVote, :count).by(1)

            expect(FictionVote.last.author).to eq(user)
            expect(FictionVote.last.fiction).to eq(fiction)
          end
        end

        context "with votes disabled" do
          let(:component) do
            create(:fiction_component)
          end

          it "doesn't allow voting" do
            expect do
              post :create, format: :js, params: params
            end.not_to change(FictionVote, :count)

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end

        context "with votes enabled but votes blocked" do
          let(:component) do
            create(:fiction_component, :with_votes_blocked)
          end

          it "doesn't allow voting" do
            expect do
              post :create, format: :js, params: params
            end.not_to change(FictionVote, :count)

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end
      end

      describe "destroy" do
        before do
          create(:fiction_vote, fiction: fiction, author: user)
        end

        context "with vote limit enabled" do
          let(:component) do
            create(:fiction_component, :with_votes_enabled, :with_vote_limit)
          end

          it "deletes the vote" do
            expect do
              delete :destroy, format: :js, params: params
            end.to change(FictionVote, :count).by(-1)

            expect(FictionVote.count).to eq(0)
          end
        end

        context "with vote limit disabled" do
          let(:component) do
            create(:fiction_component, :with_votes_enabled)
          end

          it "deletes the vote" do
            expect do
              delete :destroy, format: :js, params: params
            end.to change(FictionVote, :count).by(-1)

            expect(FictionVote.count).to eq(0)
          end
        end
      end
    end
  end
end
