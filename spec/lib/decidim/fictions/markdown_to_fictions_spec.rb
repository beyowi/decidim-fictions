# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe MarkdownToFictions do
      def should_parse_and_produce_fictions(num_fictions)
        fictions = Decidim::Fictions::Fiction.where(component: component)
        expect { parser.parse(document) }.to change { fictions.count }.by(num_fictions)
        fictions
      end

      def should_have_expected_states(fiction)
        expect(fiction.draft?).to be true
        expect(fiction.official?).to be true
      end

      def fiction_should_conform(section_level, title, body)
        fiction = Decidim::Fictions::Fiction.where(component: component).last
        expect(fiction.participatory_text_level).to eq(Decidim::Fictions::ParticipatoryTextSection::LEVELS[section_level])
        expect(fiction.title).to eq(title)
        expect(fiction.body).to eq(body)
      end

      let!(:component) { create(:fiction_component) }
      let(:parser) { MarkdownToFictions.new(component, create(:user)) }
      let(:items) { [] }
      let(:document) do
        items.join("\n")
      end

      describe "titles create sections and sub-sections" do
        context "with titles of level 1" do
          let(:title) { ::Faker::Book.title }

          before do
            items << "# #{title}\n"
          end

          it "create sections" do
            should_parse_and_produce_fictions(1)

            fiction = Fiction.last
            expect(fiction.title).to eq(title)
            expect(fiction.body).to eq(title)
            expect(fiction.position).to eq(1)
            expect(fiction.participatory_text_level).to eq(ParticipatoryTextSection::LEVELS[:section])
            should_have_expected_states(fiction)
          end
        end

        context "with titles of deeper levels" do
          let(:titles) { (0...5).collect { |idx| "#{idx}-#{::Faker::Book.title}" } }

          before do
            titles.each_with_index { |title, idx| items << "#{"#" * (2 + idx)} #{title}\n" }
          end

          it "create sub-sections" do
            expected_pos = 1

            fictions = should_parse_and_produce_fictions(5)

            fictions.order(:position).each_with_index do |fiction, idx|
              expect(fiction.title).to eq(titles[idx])
              expect(fiction.body).to eq(titles[idx])
              expect(fiction.position).to eq(expected_pos)
              expected_pos += 1
              expect(fiction.participatory_text_level).to eq("sub-section")
              should_have_expected_states(fiction)
            end
          end
        end
      end

      describe "paragraphs create articles" do
        let(:paragraph) { ::Faker::Lorem.paragraph }

        before do
          items << "#{paragraph}\n"
        end

        it "produces a fiction like an article" do
          should_parse_and_produce_fictions(1)

          fiction = Fiction.last
          # fiction titled with its numbering (position)
          expect(fiction.title).to eq("1")
          expect(fiction.body).to eq(paragraph)
          expect(fiction.position).to eq(1)
          expect(fiction.participatory_text_level).to eq(ParticipatoryTextSection::LEVELS[:article])
          should_have_expected_states(fiction)
        end
      end

      describe "links are parsed" do
        let(:text_w_link) { %[This text links to [Meta Decidim](https://meta.decidim.org "Community's meeting point").] }

        before do
          items << "#{text_w_link}\n"
        end

        it "contains the link as an html anchor" do
          should_parse_and_produce_fictions(1)

          fiction = Fiction.last
          # fiction titled with its numbering (position)
          # the paragraph and fiction's body
          expect(fiction.title).to eq("1")
          paragraph = %q(This text links to <a href="https://meta.decidim.org" title="Community's meeting point">Meta Decidim</a>.)
          expect(fiction.body).to eq(paragraph)
          expect(fiction.position).to eq(1)
          expect(fiction.participatory_text_level).to eq(ParticipatoryTextSection::LEVELS[:article])
          should_have_expected_states(fiction)
        end
      end

      describe "images are parsed" do
        let(:image) { %{Text with ![Important image for Decidim](https://meta.decidim.org/assets/decidim/decidim-logo-1f39092fb3e41d23936dc8aeadd054e2119807dccf3c395de88637e4187f0a3f.svg "Img title").} }

        before do
          items << "#{image}\n"
        end

        it "contains the image as an html img tag" do
          should_parse_and_produce_fictions(1)

          fiction = Fiction.last
          expect(fiction.title).to eq("1")
          paragraph = 'Text with <img src="https://meta.decidim.org/assets/decidim/decidim-logo-1f39092fb3e41d23936dc8aeadd054e2119807dccf3c395de88637e4187f0a3f.svg" alt="Important image for Decidim" title="Img title"/>.'
          expect(fiction.body).to eq(paragraph)
          expect(fiction.position).to eq(1)
          expect(fiction.participatory_text_level).to eq(ParticipatoryTextSection::LEVELS[:article])
          should_have_expected_states(fiction)
        end
      end

      describe "formats are parsed" do
        let(:paragraph) do
          <<~EOPARAGRAPH
            **bold text** is supported, *italics text* is supported, __underlined text__ is supported.
            As explained [here](https://daringfireball.net/projects/markdown/syntax#em) Markdown treats asterisks
            and underscores as indicators of emphasis.
            Text wrapped with one asterisk or underscore will be wrapped with an HTML &lt;em> tag; double asterisks or underscores will be wrapped with an HTML &lt;strong> tag. E.g., this input:
            - *single asterisks*
            - _single underscores_
            - **double asterisks**
            - __double underscores__
            Will produce this oputput:
            - &lt;em>single asterisks&lt;/em>
            - &lt;u>single underscores&lt;/u>
            - &lt;strong>double asterisks&lt;/strong>
            - &lt;strong>double underscores&lt;/strong>
          EOPARAGRAPH
        end

        before do
          items << "#{paragraph}\n"
        end

        it "transforms formated texts to html tags" do
          should_parse_and_produce_fictions(1)

          fiction = Fiction.last
          expect(fiction.title).to eq("1")
          paragraph = <<~EOEXPECTED
            <strong>bold text</strong> is supported, <em>italics text</em> is supported, <strong>underlined text</strong> is supported.
            As explained <a href="https://daringfireball.net/projects/markdown/syntax#em">here</a> Markdown treats asterisks
            and underscores as indicators of emphasis.
            Text wrapped with one asterisk or underscore will be wrapped with an HTML &lt;em> tag; double asterisks or underscores will be wrapped with an HTML &lt;strong> tag. E.g., this input:
            - <em>single asterisks</em>
            - <u>single underscores</u>
            - <strong>double asterisks</strong>
            - <strong>double underscores</strong>
            Will produce this oputput:
            - &lt;em>single asterisks&lt;/em>
            - &lt;u>single underscores&lt;/u>
            - &lt;strong>double asterisks&lt;/strong>
            - &lt;strong>double underscores&lt;/strong>
          EOEXPECTED
          expect(fiction.body).to eq(paragraph.strip)
          expect(fiction.position).to eq(1)
          expect(fiction.participatory_text_level).to eq(ParticipatoryTextSection::LEVELS[:article])
          should_have_expected_states(fiction)
        end
      end

      describe "lists as a whole" do
        context "when unordered" do
          let(:list) do
            <<~EOLIST
              - one
              - two
              - three
            EOLIST
          end

          before do
            items << "#{list}\n"
          end

          it "are articles" do
            should_parse_and_produce_fictions(1)
            fiction_should_conform(:article, "1", list)
          end
        end

        context "when ordered" do
          let(:list) do
            <<~EOLIST
              1. one
              2. two
              3. three
            EOLIST
          end

          before do
            items << "#{list}\n"
          end

          it "are articles" do
            should_parse_and_produce_fictions(1)
            fiction_should_conform(:article, "1", list)
          end
        end
      end
    end
  end
end
