# frozen_string_literal: true

require "spec_helper"

describe "Index Fiction Notes", type: :system do
  let(:component) { create(:fiction_component) }
  let(:organization) { component.organization }

  let(:manifest_name) { "fictions" }
  let(:fiction) { create(:fiction, component: component) }
  let(:participatory_space) { component.participatory_space }

  let(:body) { "New awesome body" }
  let(:fiction_notes_count) { 5 }

  let!(:fiction_notes) do
    create_list(
      :fiction_note,
      fiction_notes_count,
      fiction: fiction
    )
  end

  include_context "when managing a component as an admin"

  before do
    within find("tr", text: fiction.title) do
      click_link "Answer fiction"
    end
  end

  it "shows fiction notes for the current fiction" do
    fiction_notes.each do |fiction_note|
      expect(page).to have_content(fiction_note.author.name)
      expect(page).to have_content(fiction_note.body)
    end
    expect(page).to have_selector("form")
  end

  context "when the form has a text inside body" do
    it "creates a fiction note ", :slow do
      within ".new_fiction_note" do
        fill_in :fiction_note_body, with: body

        find("*[type=submit]").click
      end

      expect(page).to have_admin_callout("successfully")

      within ".comment-thread .card:last-child" do
        expect(page).to have_content("New awesome body")
      end
    end
  end

  context "when the form hasn't text inside body" do
    let(:body) { nil }

    it "don't create a fiction note", :slow do
      within ".new_fiction_note" do
        fill_in :fiction_note_body, with: body

        find("*[type=submit]").click
      end

      expect(page).to have_content("There's an error in this field.")
    end
  end
end
