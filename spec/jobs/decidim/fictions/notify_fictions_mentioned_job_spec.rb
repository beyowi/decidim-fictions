# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe NotifyFictionsMentionedJob do
      include_context "when creating a comment"
      subject { described_class }

      let(:comment) { create(:comment, commentable: commentable) }
      let(:fiction_component) { create(:fiction_component, organization: organization) }
      let(:fiction_metadata) { Decidim::ContentParsers::FictionParser::Metadata.new([]) }
      let(:linked_fiction) { create(:fiction, component: fiction_component) }
      let(:linked_fiction_official) { create(:fiction, :official, component: fiction_component) }

      describe "integration" do
        it "is correctly scheduled" do
          ActiveJob::Base.queue_adapter = :test
          fiction_metadata[:linked_fictions] << linked_fiction
          fiction_metadata[:linked_fictions] << linked_fiction_official
          comment = create(:comment)

          expect do
            Decidim::Comments::CommentCreation.publish(comment, fiction: fiction_metadata)
          end.to have_enqueued_job.with(comment.id, fiction_metadata.linked_fictions)
        end
      end

      describe "with mentioned fictions" do
        let(:linked_fictions) do
          [
            linked_fiction.id,
            linked_fiction_official.id
          ]
        end

        let!(:space_admin) do
          create(:process_admin, participatory_process: linked_fiction_official.component.participatory_space)
        end

        it "notifies the author about it" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.fictions.fiction_mentioned",
              event_class: Decidim::Fictions::FictionMentionedEvent,
              resource: commentable,
              affected_users: [linked_fiction.creator_author],
              extra: {
                comment_id: comment.id,
                mentioned_fiction_id: linked_fiction.id
              }
            )

          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.fictions.fiction_mentioned",
              event_class: Decidim::Fictions::FictionMentionedEvent,
              resource: commentable,
              affected_users: [space_admin],
              extra: {
                comment_id: comment.id,
                mentioned_fiction_id: linked_fiction_official.id
              }
            )

          subject.perform_now(comment.id, linked_fictions)
        end
      end
    end
  end
end
