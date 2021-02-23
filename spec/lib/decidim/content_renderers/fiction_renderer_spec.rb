# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ContentRenderers
    describe FictionRenderer do
      let!(:renderer) { Decidim::ContentRenderers::FictionRenderer.new(content) }

      describe "on parse" do
        subject { renderer.render }

        context "when content is nil" do
          let(:content) { nil }

          it { is_expected.to eq("") }
        end

        context "when content is empty string" do
          let(:content) { "" }

          it { is_expected.to eq("") }
        end

        context "when conent has no gids" do
          let(:content) { "whatever content with @mentions and #hashes but no gids." }

          it { is_expected.to eq(content) }
        end

        context "when content has one gid" do
          let(:fiction) { create(:fiction) }
          let(:content) do
            "This content references fiction #{fiction.to_global_id}."
          end

          it { is_expected.to eq("This content references fiction #{fiction_as_html_link(fiction)}.") }
        end

        context "when content has many links" do
          let(:fiction_1) { create(:fiction) }
          let(:fiction_2) { create(:fiction) }
          let(:fiction_3) { create(:fiction) }
          let(:content) do
            gid1 = fiction_1.to_global_id
            gid2 = fiction_2.to_global_id
            gid3 = fiction_3.to_global_id
            "This content references the following fictions: #{gid1}, #{gid2} and #{gid3}. Great?I like them!"
          end

          it { is_expected.to eq("This content references the following fictions: #{fiction_as_html_link(fiction_1)}, #{fiction_as_html_link(fiction_2)} and #{fiction_as_html_link(fiction_3)}. Great?I like them!") }
        end
      end

      def fiction_url(fiction)
        Decidim::ResourceLocatorPresenter.new(fiction).path
      end

      def fiction_as_html_link(fiction)
        href = fiction_url(fiction)
        title = fiction.title
        %(<a href="#{href}">#{title}</a>)
      end
    end
  end
end
