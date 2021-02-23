# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe AnswerFiction do
        subject { command.call }

        let(:command) { described_class.new(form, fiction) }
        let(:fiction) { create(:fiction) }
        let(:current_user) { create(:user, :admin) }
        let(:form) do
          FictionAnswerForm.from_params(form_params).with_context(
            current_user: current_user,
            current_component: fiction.component,
            current_organization: fiction.component.organization
          )
        end

        let(:form_params) do
          {
            internal_state: "rejected",
            answer: { en: "Foo" },
            cost: 2000,
            cost_report: { en: "Cost report" },
            execution_period: { en: "Execution period" }
          }
        end

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "publish the fiction answer" do
          expect { subject }.to change { fiction.reload.published_state? } .to(true)
        end

        it "changes the fiction state" do
          expect { subject }.to change { fiction.reload.state } .to("rejected")
        end

        it "traces the action", versioning: true do
          expect(Decidim.traceability)
            .to receive(:perform_action!)
            .with("answer", fiction, form.current_user)
            .and_call_original

          expect { subject }.to change(Decidim::ActionLog, :count)
          action_log = Decidim::ActionLog.last
          expect(action_log.version).to be_present
          expect(action_log.version.event).to eq "update"
        end

        it "notifies the fiction answer" do
          expect(NotifyFictionAnswer)
            .to receive(:call)
            .with(fiction, nil)

          subject
        end

        context "when the form is not valid" do
          before do
            expect(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { subject }.to broadcast(:invalid)
          end

          it "doesn't change the fiction state" do
            expect { subject }.not_to(change { fiction.reload.state })
          end
        end

        context "when applying over an already answered fiction" do
          let(:fiction) { create(:fiction, :accepted) }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "changes the fiction state" do
            expect { subject }.to change { fiction.reload.state } .to("rejected")
          end

          it "notifies the fiction new answer" do
            expect(NotifyFictionAnswer)
              .to receive(:call)
              .with(fiction, "accepted")

            subject
          end
        end

        context "when fiction answer should not be published immediately" do
          let(:fiction) { create(:fiction, component: component) }
          let(:component) { create(:fiction_component, :without_publish_answers_immediately) }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "changes the fiction internal state" do
            expect { subject }.to change { fiction.reload.internal_state } .to("rejected")
          end

          it "doesn't publish the fiction answer" do
            expect { subject }.not_to change { fiction.reload.published_state? } .from(false)
          end

          it "doesn't notify the fiction answer" do
            expect(NotifyFictionAnswer)
              .not_to receive(:call)

            subject
          end
        end
      end
    end
  end
end
