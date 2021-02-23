# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe UpdateFictionScope do
        describe "call" do
          let!(:fiction) { create :fiction }
          let!(:fictions) { create_list(:fiction, 3, component: fiction.component) }
          let!(:scope_one) { create :scope, organization: fiction.organization }
          let!(:scope) { create :scope, organization: fiction.organization }

          context "with no scope" do
            it "broadcasts invalid_scope" do
              expect { described_class.call(nil, fiction.id) }.to broadcast(:invalid_scope)
            end
          end

          context "with no fictions" do
            it "broadcasts invalid_fiction_ids" do
              expect { described_class.call(scope.id, nil) }.to broadcast(:invalid_fiction_ids)
            end
          end

          describe "with a scope and fictions" do
            context "when the scope is the same as the fiction's scope" do
              before do
                fiction.update!(scope: scope)
              end

              it "doesn't update the fiction" do
                expect(fiction).not_to receive(:update!)
                described_class.call(fiction.scope.id, fiction.id)
              end
            end

            context "when the scope is diferent from the fiction's scope" do
              before do
                fictions.each { |p| p.update!(scope: scope_one) }
              end

              it "broadcasts update_fictions_scope" do
                expect { described_class.call(scope.id, fictions.pluck(:id)) }.to broadcast(:update_fictions_scope)
              end

              it "updates the fiction" do
                described_class.call(scope.id, fiction.id)

                expect(fiction.reload.scope).to eq(scope)
              end
            end
          end
        end
      end
    end
  end
end
