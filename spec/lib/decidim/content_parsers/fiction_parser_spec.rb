# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ContentParsers
    describe FictionParser do
      let(:organization) { create(:organization) }
      let(:component) { create(:fiction_component, organization: organization) }
      let(:context) { { current_organization: organization } }
      let!(:parser) { Decidim::ContentParsers::FictionParser.new(content, context) }

      describe "ContentParser#parse is invoked" do
        let(:content) { "" }

        it "must call FictionParser.parse" do
          expect(described_class).to receive(:new).with(content, context).and_return(parser)

          result = Decidim::ContentProcessor.parse(content, context)

          expect(result.rewrite).to eq ""
          expect(result.metadata[:fiction].class).to eq Decidim::ContentParsers::FictionParser::Metadata
        end
      end

      describe "on parse" do
        subject { parser.rewrite }

        context "when content is nil" do
          let(:content) { nil }

          it { is_expected.to eq("") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::FictionParser::Metadata)
            expect(parser.metadata.linked_fictions).to eq([])
          end
        end

        context "when content is empty string" do
          let(:content) { "" }

          it { is_expected.to eq("") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::FictionParser::Metadata)
            expect(parser.metadata.linked_fictions).to eq([])
          end
        end

        context "when conent has no links" do
          let(:content) { "whatever content with @mentions and #hashes but no links." }

          it { is_expected.to eq(content) }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::FictionParser::Metadata)
            expect(parser.metadata.linked_fictions).to eq([])
          end
        end

        context "when content links to an organization different from current" do
          let(:fiction) { create(:fiction, component: component) }
          let(:external_fiction) { create(:fiction, component: create(:fiction_component, organization: create(:organization))) }
          let(:content) do
            url = fiction_url(external_fiction)
            "This content references fiction #{url}."
          end

          it "does not recognize the fiction" do
            subject
            expect(parser.metadata.linked_fictions).to eq([])
          end
        end

        context "when content has one link" do
          let(:fiction) { create(:fiction, component: component) }
          let(:content) do
            url = fiction_url(fiction)
            "This content references fiction #{url}."
          end

          it { is_expected.to eq("This content references fiction #{fiction.to_global_id}.") }

          it "has metadata with the fiction" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::FictionParser::Metadata)
            expect(parser.metadata.linked_fictions).to eq([fiction.id])
          end
        end

        context "when content has one link that is a simple domain" do
          let(:link) { "aaa:bbb" }
          let(:content) do
            "This content contains #{link} which is not a URI."
          end

          it { is_expected.to eq(content) }

          it "has metadata with the fiction" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::FictionParser::Metadata)
            expect(parser.metadata.linked_fictions).to be_empty
          end
        end

        context "when content has many links" do
          let(:fiction1) { create(:fiction, component: component) }
          let(:fiction2) { create(:fiction, component: component) }
          let(:fiction3) { create(:fiction, component: component) }
          let(:content) do
            url1 = fiction_url(fiction1)
            url2 = fiction_url(fiction2)
            url3 = fiction_url(fiction3)
            "This content references the following fictions: #{url1}, #{url2} and #{url3}. Great?I like them!"
          end

          it { is_expected.to eq("This content references the following fictions: #{fiction1.to_global_id}, #{fiction2.to_global_id} and #{fiction3.to_global_id}. Great?I like them!") }

          it "has metadata with all linked fictions" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::FictionParser::Metadata)
            expect(parser.metadata.linked_fictions).to eq([fiction1.id, fiction2.id, fiction3.id])
          end
        end

        context "when content has a link that is not in a fictions component" do
          let(:fiction) { create(:fiction, component: component) }
          let(:content) do
            url = fiction_url(fiction).sub(%r{/fictions/}, "/something-else/")
            "This content references a non-fiction with same ID as a fiction #{url}."
          end

          it { is_expected.to eq(content) }

          it "has metadata with no reference to the fiction" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::FictionParser::Metadata)
            expect(parser.metadata.linked_fictions).to be_empty
          end
        end

        context "when content has words similar to links but not links" do
          let(:similars) do
            %w(AA:aaa AA:sss aa:aaa aa:sss aaa:sss aaaa:sss aa:ssss aaa:ssss)
          end
          let(:content) do
            "This content has similars to links: #{similars.join}. Great! Now are not treated as links"
          end

          it { is_expected.to eq(content) }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::FictionParser::Metadata)
            expect(parser.metadata.linked_fictions).to be_empty
          end
        end

        context "when fiction in content does not exist" do
          let(:fiction) { create(:fiction, component: component) }
          let(:url) { fiction_url(fiction) }
          let(:content) do
            fiction.destroy
            "This content references fiction #{url}."
          end

          it { is_expected.to eq("This content references fiction #{url}.") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::FictionParser::Metadata)
            expect(parser.metadata.linked_fictions).to eq([])
          end
        end

        context "when fiction is linked via ID" do
          let(:fiction) { create(:fiction, component: component) }
          let(:content) { "This content references fiction ~#{fiction.id}." }

          it { is_expected.to eq("This content references fiction #{fiction.to_global_id}.") }

          it "has metadata with the fiction" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::FictionParser::Metadata)
            expect(parser.metadata.linked_fictions).to eq([fiction.id])
          end
        end
      end

      def fiction_url(fiction)
        Decidim::ResourceLocatorPresenter.new(fiction).url
      end
    end
  end
end
