# frozen_string_literal: true

require "spec_helper"

describe Decidim::Fictions::FictionCell, type: :cell do
  controller Decidim::Fictions::FictionsController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/fictions/fiction", model) }
  let!(:official_fiction) { create(:fiction, :official) }
  let!(:user_fiction) { create(:fiction) }
  let!(:current_user) { create(:user, :confirmed, organization: model.participatory_space.organization) }

  before do
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  context "when rendering an official fiction" do
    let(:model) { official_fiction }

    it "renders the card" do
      expect(subject).to have_css(".card--fiction")
    end
  end

  context "when rendering a user fiction" do
    let(:model) { user_fiction }

    it "renders the card" do
      expect(subject).to have_css(".card--fiction")
    end
  end
end
