# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe UpdateFictionCategory do
        describe "call" do
          let(:organization) { create(:organization) }

          let!(:fiction) { create :fiction }
          let!(:fictions) { create_list(:fiction, 3, component: fiction.component) }
          let!(:category_one) { create :category, participatory_space: fiction.component.participatory_space }
          let!(:category) { create :category, participatory_space: fiction.component.participatory_space }

          context "with no category" do
            it "broadcasts invalid_category" do
              expect { described_class.call(nil, fiction.id) }.to broadcast(:invalid_category)
            end
          end

          context "with no fictions" do
            it "broadcasts invalid_fiction_ids" do
              expect { described_class.call(category.id, nil) }.to broadcast(:invalid_fiction_ids)
            end
          end

          describe "with a category and fictions" do
            context "when the category is the same as the fiction's category" do
              before do
                fiction.update!(category: category)
              end

              it "doesn't update the fiction" do
                expect(fiction).not_to receive(:update!)
                described_class.call(fiction.category.id, fiction.id)
              end
            end

            context "when the category is diferent from the fiction's category" do
              before do
                fictions.each { |p| p.update!(category: category_one) }
              end

              it "broadcasts update_fictions_category" do
                expect { described_class.call(category.id, fictions.pluck(:id)) }.to broadcast(:update_fictions_category)
              end

              it "updates the fiction" do
                described_class.call(category.id, fiction.id)

                expect(fiction.reload.category).to eq(category)
              end
            end
          end
        end
      end
    end
  end
end
