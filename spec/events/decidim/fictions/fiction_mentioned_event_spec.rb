# frozen_string_literal: true

require "spec_helper"

describe Decidim::Fictions::FictionMentionedEvent do
  include_context "when a simple event"

  let(:event_name) { "decidim.events.fictions.fiction_mentioned" }
  let(:organization) { create :organization }
  let(:author) { create :user, organization: organization }

  let(:source_fiction) { create :fiction, component: create(:fiction_component, organization: organization), title: "Fiction A" }
  let(:mentioned_fiction) { create :fiction, component: create(:fiction_component, organization: organization), title: "Fiction B" }
  let(:resource) { source_fiction }
  let(:extra) do
    {
      mentioned_fiction_id: mentioned_fiction.id
    }
  end

  it_behaves_like "a simple event"

  describe "types" do
    subject { described_class }

    it "supports notifications" do
      expect(subject.types).to include :notification
    end

    it "supports emails" do
      expect(subject.types).to include :email
    end
  end

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("Your fiction \"#{mentioned_fiction.title}\" has been mentioned")
    end
  end

  context "with content" do
    let(:content) do
      "Your fiction \"#{mentioned_fiction.title}\" has been mentioned " \
        "<a href=\"#{resource_url}\">in this space</a> in the comments."
    end

    describe "email_intro" do
      let(:resource_url) { resource_locator(source_fiction).url }

      it "is generated correctly" do
        expect(subject.email_intro).to eq(content)
      end
    end

    describe "notification_title" do
      let(:resource_url) { resource_locator(source_fiction).path }

      it "is generated correctly" do
        expect(subject.notification_title).to include(content)
      end
    end
  end
end
