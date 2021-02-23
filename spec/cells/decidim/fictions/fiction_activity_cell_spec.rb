# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe FictionActivityCell, type: :cell do
      controller Decidim::LastActivitiesController

      let!(:fiction) { create(:fiction) }
      let(:hashtag) { create(:hashtag, name: "myhashtag") }
      let(:action_log) do
        create(
          :action_log,
          resource: fiction,
          organization: fiction.organization,
          component: fiction.component,
          participatory_space: fiction.participatory_space
        )
      end

      context "when rendering" do
        it "renders the card" do
          html = cell("decidim/fictions/fiction_activity", action_log).call
          expect(html).to have_css(".card__content")
          expect(html).to have_content("New fiction")
        end

        context "when the fiction has a hashtags" do
          before do
            body = "Fiction with #myhashtag"
            parsed_body = Decidim::ContentProcessor.parse(body, current_organization: fiction.organization)
            fiction.body = parsed_body.rewrite
            fiction.save
          end

          it "correctly renders fictions with mentions" do
            html = cell("decidim/fictions/fiction_activity", action_log).call
            expect(html).to have_no_content("gid://")
            expect(html).to have_content("#myhashtag")
          end
        end
      end
    end
  end
end
