# frozen_string_literal: true

shared_examples "export fictions" do
  let!(:fictions) { create_list :fiction, 3, component: current_component }

  it "exports a CSV" do
    find(".exports.dropdown").click
    perform_enqueued_jobs { click_link "Fictions as CSV" }

    within ".callout.success" do
      expect(page).to have_content("in progress")
    end

    expect(last_email.subject).to include("fictions", "csv")
    expect(last_email.attachments.length).to be_positive
    expect(last_email.attachments.first.filename).to match(/^fictions.*\.zip$/)
  end

  it "exports a JSON" do
    find(".exports.dropdown").click
    perform_enqueued_jobs { click_link "Fictions as JSON" }

    within ".callout.success" do
      expect(page).to have_content("in progress")
    end

    expect(last_email.subject).to include("fictions", "json")
    expect(last_email.attachments.length).to be_positive
    expect(last_email.attachments.first.filename).to match(/^fictions.*\.zip$/)
  end
end
