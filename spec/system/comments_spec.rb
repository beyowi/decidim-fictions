# frozen_string_literal: true

require "spec_helper"

describe "Comments", type: :system do
  let!(:component) { create(:fiction_component, organization: organization) }
  let!(:author) { create(:user, :confirmed, organization: organization) }
  let!(:commentable) { create(:fiction, component: component, users: [author]) }

  let(:resource_path) { resource_locator(commentable).path }

  include_examples "comments"
end
