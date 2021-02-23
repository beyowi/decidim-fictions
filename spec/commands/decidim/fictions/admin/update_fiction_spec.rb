# frozen_string_literal: true

require "spec_helper"

describe Decidim::Fictions::Admin::UpdateFiction do
  let(:form_klass) { Decidim::Fictions::Admin::FictionForm }

  let(:component) { create(:fiction_component) }
  let(:organization) { component.organization }
  let(:user) { create :user, :admin, :confirmed, organization: organization }
  let(:form) do
    form_klass.from_params(
      form_params
    ).with_context(
      current_organization: organization,
      current_participatory_space: component.participatory_space,
      current_user: user,
      current_component: component
    )
  end

  let!(:fiction) { create :fiction, :official, component: component }

  let(:has_address) { false }
  let(:address) { nil }
  let(:attachment_params) { nil }
  let(:uploaded_photos) { [] }
  let(:current_photos) { [] }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }

  describe "call" do
    let(:form_params) do
      {
        title: "A reasonable fiction title",
        body: "A reasonable fiction body",
        address: address,
        has_address: has_address,
        attachment: attachment_params,
        photos: current_photos,
        add_photos: uploaded_photos
      }
    end

    let(:command) do
      described_class.new(form, fiction)
    end

    describe "when the form is not valid" do
      before do
        expect(form).to receive(:invalid?).and_return(true)
      end

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end

      it "doesn't update the fiction" do
        expect do
          command.call
        end.not_to change(fiction, :title)
      end
    end

    describe "when the form is valid" do
      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "updates the fiction" do
        expect do
          command.call
        end.to change(fiction, :title)
      end

      it "traces the update", versioning: true do
        expect(Decidim.traceability)
          .to receive(:update!)
          .with(fiction, user, a_kind_of(Hash))
          .and_call_original

        expect { command.call }.to change(Decidim::ActionLog, :count)

        action_log = Decidim::ActionLog.last
        expect(action_log.version).to be_present
        expect(action_log.version.event).to eq "update"
      end

      context "when geocoding is enabled" do
        let(:component) { create(:fiction_component, :with_geocoding_enabled) }

        context "when the has address checkbox is checked" do
          let(:has_address) { true }

          context "when the address is present" do
            let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }

            before do
              stub_geocoding(address, [latitude, longitude])
            end

            it "sets the latitude and longitude" do
              command.call
              fiction = Decidim::Fictions::Fiction.last

              expect(fiction.latitude).to eq(latitude)
              expect(fiction.longitude).to eq(longitude)
            end
          end
        end
      end

      context "when attachments are allowed", processing_uploads_for: Decidim::AttachmentUploader do
        let(:component) { create(:fiction_component, :with_attachments_allowed) }
        let(:attachment_params) do
          {
            title: "My attachment",
            file: Decidim::Dev.test_file("city.jpeg", "image/jpeg")
          }
        end

        it "creates an atachment for the fiction" do
          expect { command.call }.to change(Decidim::Attachment, :count).by(1)
          last_fiction = Decidim::Fictions::Fiction.last
          last_attachment = Decidim::Attachment.last
          expect(last_attachment.attached_to).to eq(last_fiction)
        end

        context "when attachment is left blank" do
          let(:attachment_params) do
            {
              title: ""
            }
          end

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end
        end
      end

      it_behaves_like "admin manages resource gallery" do
        let(:component) { create(:fiction_component, :with_attachments_allowed) }
        let!(:resource) { fiction }
        let(:command) { described_class.new(form, resource) }
        let(:resource_class) { Decidim::Fictions::Fiction }
        let(:attachment_params) { { title: "" } }
      end
    end
  end
end
