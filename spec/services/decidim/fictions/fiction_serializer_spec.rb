# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe FictionSerializer do
      subject do
        described_class.new(fiction)
      end

      let!(:fiction) { create(:fiction, :accepted) }
      let!(:category) { create(:category, participatory_space: component.participatory_space) }
      let!(:scope) { create(:scope, organization: component.participatory_space.organization) }
      let(:participatory_process) { component.participatory_space }
      let(:component) { fiction.component }

      let!(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
      let(:meetings) { create_list(:meeting, 2, component: meetings_component) }

      let!(:fictions_component) { create(:component, manifest_name: "fictions", participatory_space: participatory_process) }
      let(:other_fictions) { create_list(:fiction, 2, component: fictions_component) }

      let(:expected_answer) do
        answer = fiction.answer
        Decidim.available_locales.each_with_object({}) do |locale, result|
          result[locale.to_s] = if answer.is_a?(Hash)
                                  answer[locale.to_s] || ""
                                else
                                  ""
                                end
        end
      end

      before do
        fiction.update!(category: category)
        fiction.update!(scope: scope)
        fiction.link_resources(meetings, "fictions_from_meeting")
        fiction.link_resources(other_fictions, "copied_from_component")
      end

      describe "#serialize" do
        let(:serialized) { subject.serialize }

        it "serializes the id" do
          expect(serialized).to include(id: fiction.id)
        end

        it "serializes the category" do
          expect(serialized[:category]).to include(id: category.id)
          expect(serialized[:category]).to include(name: category.name)
        end

        it "serializes the scope" do
          expect(serialized[:scope]).to include(id: scope.id)
          expect(serialized[:scope]).to include(name: scope.name)
        end

        it "serializes the title" do
          expect(serialized).to include(title: fiction.title)
        end

        it "serializes the body" do
          expect(serialized).to include(body: fiction.body)
        end

        it "serializes the amount of supports" do
          expect(serialized).to include(supports: fiction.fiction_votes_count)
        end

        it "serializes the amount of comments" do
          expect(serialized).to include(comments: fiction.comments.count)
        end

        it "serializes the date of creation" do
          expect(serialized).to include(published_at: fiction.published_at)
        end

        it "serializes the url" do
          expect(serialized[:url]).to include("http", fiction.id.to_s)
        end

        it "serializes the component" do
          expect(serialized[:component]).to include(id: fiction.component.id)
        end

        it "serializes the meetings" do
          expect(serialized[:meeting_urls].length).to eq(2)
          expect(serialized[:meeting_urls].first).to match(%r{http.*/meetings})
        end

        it "serializes the participatory space" do
          expect(serialized[:participatory_space]).to include(id: participatory_process.id)
          expect(serialized[:participatory_space][:url]).to include("http", participatory_process.slug)
        end

        it "serializes the state" do
          expect(serialized).to include(state: fiction.state)
        end

        it "serializes the reference" do
          expect(serialized).to include(reference: fiction.reference)
        end

        it "serializes the answer" do
          expect(serialized).to include(answer: expected_answer)
        end

        it "serializes the amount of attachments" do
          expect(serialized).to include(attachments: fiction.attachments.count)
        end

        it "serializes the endorsements" do
          expect(serialized[:endorsements]).to include(total_count: fiction.endorsements.count)
          expect(serialized[:endorsements]).to include(user_endorsements: fiction.endorsements.for_listing.map { |identity| identity.normalized_author&.name })
        end

        it "serializes related fictions" do
          expect(serialized[:related_fictions].length).to eq(2)
          expect(serialized[:related_fictions].first).to match(%r{http.*/fictions})
        end

        it "serializes if fiction is_amend" do
          expect(serialized).to include(is_amend: fiction.emendation?)
        end

        it "serializes the original fiction" do
          expect(serialized[:original_fiction]).to include(title: fiction&.amendable&.title)
          expect(serialized[:original_fiction][:url]).to be_nil || include("http", fiction.id.to_s)
        end

        context "with fiction having an answer" do
          let!(:fiction) { create(:fiction, :with_answer) }

          it "serializes the answer" do
            expect(serialized).to include(answer: expected_answer)
          end
        end
      end
    end
  end
end
