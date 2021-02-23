# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe PublishAnswers do
        subject { command.call }

        let(:command) { described_class.new(component, user, fiction_ids) }
        let(:fiction_ids) { fictions.map(&:id) }
        let(:fictions) { create_list(:fiction, 5, :accepted_not_published, component: component) }
        let(:component) { create(:fiction_component) }
        let(:user) { create(:user, :admin) }

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "publish the answers" do
          expect { subject }.to change { fictions.map { |fiction| fiction.reload.published_state? } .uniq } .to([true])
        end

        it "changes the fictions published state" do
          expect { subject }.to change { fictions.map { |fiction| fiction.reload.state } .uniq } .from([nil]).to(["accepted"])
        end

        it "traces the action", versioning: true do
          fictions.each do |fiction|
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with("publish_answer", fiction, user)
              .and_call_original
          end

          expect { subject }.to change(Decidim::ActionLog, :count)
          action_log = Decidim::ActionLog.last
          expect(action_log.version).to be_present
          expect(action_log.version.event).to eq "update"
        end

        it "notifies the answers" do
          fictions.each do |fiction|
            expect(NotifyFictionAnswer)
              .to receive(:call)
              .with(fiction, nil)
          end

          subject
        end

        context "when fiction ids belong to other component" do
          let(:fictions) { create_list(:fiction, 5, :accepted) }

          it "broadcasts invalid" do
            expect { subject }.to broadcast(:invalid)
          end

          it "doesn't publish the answers" do
            expect { subject }.not_to(change { fictions.map { |fiction| fiction.reload.published_state? } .uniq })
          end

          it "doesn't trace the action" do
            expect(Decidim.traceability)
              .not_to receive(:perform_action!)

            subject
          end

          it "doesn't notify the answers" do
            expect(NotifyFictionAnswer).not_to receive(:call)

            subject
          end
        end
      end
    end
  end
end
