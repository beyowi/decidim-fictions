# frozen_string_literal: true

require "decidim/dev/test/rspec_support/capybara_data_picker"

module Capybara
  module FictionsPicker
    include DataPicker

    RSpec::Matchers.define :have_fictions_picked do |expected|
      match do |fictions_picker|
        data_picker = fictions_picker.data_picker

        expected.each do |fiction|
          expect(data_picker).to have_selector(".picker-values div input[value='#{fiction.id}']", visible: :all)
          expect(data_picker).to have_selector(:xpath, "//div[contains(@class,'picker-values')]/div/a[text()[contains(.,\"#{fiction.title}\")]]")
        end
      end
    end

    RSpec::Matchers.define :have_fictions_not_picked do |expected|
      match do |fictions_picker|
        data_picker = fictions_picker.data_picker

        expected.each do |fiction|
          expect(data_picker).not_to have_selector(".picker-values div input[value='#{fiction.id}']", visible: :all)
          expect(data_picker).not_to have_selector(:xpath, "//div[contains(@class,'picker-values')]/div/a[text()[contains(.,\"#{fiction.title}\")]]")
        end
      end
    end

    def fictions_pick(fictions_picker, fictions)
      data_picker = fictions_picker.data_picker

      expect(data_picker).to have_selector(".picker-prompt")
      data_picker.find(".picker-prompt").click

      fictions.each do |fiction|
        data_picker_choose_value(fiction.id)
      end
      data_picker_close

      expect(fictions_picker).to have_fictions_picked(fictions)
    end
  end
end

RSpec.configure do |config|
  config.include Capybara::FictionsPicker, type: :system
end
