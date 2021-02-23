# frozen_string_literal: true

shared_examples "view fiction details from admin" do
  include ActionView::Helpers::TextHelper

  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: participatory_process_scope) }
  let(:participatory_process_scope) { nil }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  it "has a link to the fiction" do
    go_to_admin_fiction_page(fiction)
    path = "processes/#{participatory_process.slug}/f/#{component.id}/fictions/#{fiction.id}"

    expect(page).to have_selector("a", text: path)
  end

  describe "with authors" do
    it "has a link to each author profile" do
      go_to_admin_fiction_page(fiction)

      within "#fiction-authors-list" do
        fiction.authors.each do |author|
          list_item = find("li", text: author.name)

          within list_item do
            expect(page).to have_selector("a", text: author.name)
            expect(page).to have_selector(:xpath, './/a[@title="Contact"]')
          end
        end
      end
    end

    context "when it has an organization as an author" do
      let!(:fiction) { create :fiction, :official, component: current_component }

      it "doesn't show a link to the organization" do
        go_to_admin_fiction_page(fiction)

        within "#fiction-authors-list" do
          expect(page).to have_no_selector("a", text: "Official fiction")
          expect(page).to have_content("Official fiction")
        end
      end
    end
  end

  it "shows the fiction body" do
    go_to_admin_fiction_page(fiction)

    expect(page).to have_content(strip_tags(fiction.body).strip)
  end

  describe "with an specific creation date" do
    let!(:fiction) { create :fiction, component: current_component, created_at: Time.zone.parse("2020-01-29 15:00") }

    it "shows the fiction creation date" do
      go_to_admin_fiction_page(fiction)

      expect(page).to have_content("Creation date: 29/01/2020 15:00")
    end
  end

  describe "with supports" do
    before do
      create_list :fiction_vote, 2, fiction: fiction
    end

    it "shows the number of supports" do
      go_to_admin_fiction_page(fiction)

      expect(page).to have_content("Supports count: 2")
    end

    it "shows the ranking by supports" do
      another_fiction = create :fiction, component: component
      create :fiction_vote, fiction: another_fiction
      go_to_admin_fiction_page(fiction)

      expect(page).to have_content("Ranking by supports: 1 of")
    end
  end

  describe "with endorsements" do
    let!(:endorsements) do
      2.times.collect do
        create(:endorsement, resource: fiction, author: build(:user, organization: organization))
      end
    end

    it "shows the number of endorsements" do
      go_to_admin_fiction_page(fiction)

      expect(page).to have_content("Endorsements count: 2")
    end

    it "shows the ranking by endorsements" do
      another_fiction = create :fiction, component: component
      create(:endorsement, resource: another_fiction, author: build(:user, organization: organization))
      go_to_admin_fiction_page(fiction)

      expect(page).to have_content("Ranking by endorsements: 1 of")
    end

    it "has a link to each endorser profile" do
      go_to_admin_fiction_page(fiction)

      within "#fiction-endorsers-list" do
        fiction.endorsements.for_listing.each do |endorsement|
          endorser = endorsement.normalized_author
          expect(page).to have_selector("a", text: endorser.name)
        end
      end
    end

    context "with more than 5 endorsements" do
      let!(:endorsements) do
        6.times.collect do
          create(:endorsement, resource: fiction, author: build(:user, organization: organization))
        end
      end

      it "links to the fiction page to check the rest of endorsements" do
        go_to_admin_fiction_page(fiction)

        within "#fiction-endorsers-list" do
          expect(page).to have_selector("a", text: "and 1 more")
        end
      end
    end
  end

  it "shows the number of amendments" do
    create :fiction_amendment, amendable: fiction
    go_to_admin_fiction_page(fiction)

    expect(page).to have_content("Amendments count: 1")
  end

  describe "with comments" do
    before do
      create_list :comment, 2, commentable: fiction, alignment: -1
      create_list :comment, 3, commentable: fiction, alignment: 1
      create :comment, commentable: fiction, alignment: 0

      go_to_admin_fiction_page(fiction)
    end

    it "shows the number of comments" do
      expect(page).to have_content("Comments count: 6")
    end

    it "groups the number of comments by alignment" do
      within "#fiction-comments-alignment-count" do
        expect(page).to have_content("Favor: 3")
        expect(page).to have_content("Neutral: 1")
        expect(page).to have_content("Against: 2")
      end
    end
  end

  context "with related meetings" do
    let(:meeting_component) { create :meeting_component, participatory_space: participatory_process }
    let(:meeting) { create :meeting, component: meeting_component }

    it "lists the related meetings" do
      fiction.link_resources(meeting, "fictions_from_meeting")
      go_to_admin_fiction_page(fiction)

      within "#related-meetings" do
        expect(page).to have_selector("a", text: translated(meeting.title))
      end
    end
  end

  context "with attached documents" do
    it "lists the documents" do
      document = create :attachment, :with_pdf, attached_to: fiction
      go_to_admin_fiction_page(fiction)

      within "#documents" do
        expect(page).to have_selector("a", text: translated(document.title))
        expect(page).to have_content(document.file_type)
      end
    end
  end

  context "with attached photos" do
    it "lists the documents" do
      image = create :attachment, :with_image, attached_to: fiction
      go_to_admin_fiction_page(fiction)

      within "#photos" do
        expect(page).to have_selector(:xpath, "//img[@src=\"#{image.thumbnail_url}\"]")
        expect(page).to have_selector(:xpath, "//a[@href=\"#{image.big_url}\"]")
      end
    end
  end

  def go_to_admin_fiction_page(fiction)
    within find("tr", text: fiction.title) do
      find("a", class: "action-icon--show-fiction").click
    end
  end
end
