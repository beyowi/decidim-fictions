# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"

module Decidim
  module Fictions
    describe FictionsType, type: :graphql do
      include_context "with a graphql type"
      let(:model) { create(:fiction_component) }

      it_behaves_like "a component query type"

      describe "fictions" do
        let!(:draft_fictions) { create_list(:fiction, 2, :draft, component: model) }
        let!(:published_fictions) { create_list(:fiction, 2, component: model) }
        let!(:other_fictions) { create_list(:fiction, 2) }

        let(:query) { "{ fictions { edges { node { id } } } }" }

        it "returns the published fictions" do
          ids = response["fictions"]["edges"].map { |edge| edge["node"]["id"] }
          expect(ids).to include(*published_fictions.map(&:id).map(&:to_s))
          expect(ids).not_to include(*draft_fictions.map(&:id).map(&:to_s))
          expect(ids).not_to include(*other_fictions.map(&:id).map(&:to_s))
        end
      end

      describe "fiction" do
        let(:query) { "query Fiction($id: ID!){ fiction(id: $id) { id } }" }
        let(:variables) { { id: fiction.id.to_s } }

        context "when the fiction belongs to the component" do
          let!(:fiction) { create(:fiction, component: model) }

          it "finds the fiction" do
            expect(response["fiction"]["id"]).to eq(fiction.id.to_s)
          end
        end

        context "when the fiction doesn't belong to the component" do
          let!(:fiction) { create(:fiction, component: create(:fiction_component)) }

          it "returns null" do
            expect(response["fiction"]).to be_nil
          end
        end

        context "when the fiction is not published" do
          let!(:fiction) { create(:fiction, :draft, component: model) }

          it "returns null" do
            expect(response["fiction"]).to be_nil
          end
        end
      end
    end
  end
end
