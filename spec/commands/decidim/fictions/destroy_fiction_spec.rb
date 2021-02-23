# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe DestroyFiction do
      describe "call" do
        let(:component) { create(:fiction_component) }
        let(:organization) { component.organization }
        let(:current_user) { create(:user, organization: organization) }
        let(:other_user) { create(:user, organization: organization) }
        let!(:fiction) { create :fiction, component: component, users: [current_user] }
        let(:fiction_draft) { create(:fiction, :draft, component: component, users: [current_user]) }
        let!(:fiction_draft_other) { create :fiction, component: component, users: [other_user] }

        it "broadcasts ok" do
          expect { described_class.call(fiction_draft, current_user) }.to broadcast(:ok)
          expect { fiction_draft.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "broadcasts invalid when the fiction is not a draft" do
          expect { described_class.call(fiction, current_user) }.to broadcast(:invalid)
        end

        it "broadcasts invalid when the fiction_draft is from another author" do
          expect { described_class.call(fiction_draft_other, current_user) }.to broadcast(:invalid)
        end
      end
    end
  end
end
