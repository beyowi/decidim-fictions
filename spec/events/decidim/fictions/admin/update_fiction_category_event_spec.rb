# frozen_string_literal: true

require "spec_helper"

describe Decidim::Fictions::Admin::UpdateFictionCategoryEvent do
  let(:resource) { create :fiction, title: "My super fiction" }
  let(:event_name) { "decidim.events.fictions.fiction_update_category" }

  include_context "when a simple event"
  it_behaves_like "a simple event"

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("The #{resource.title} fiction category has been updated")
    end
  end

  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro)
        .to eq("An admin has updated the category of your fiction \"#{resource.title}\", check it out in this page:")
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to eq("You have received this notification because you are the author of the fiction.")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to include("The <a href=\"#{resource_path}\">#{resource.title}</a> fiction category has been updated by an admin.")
    end
  end
end
