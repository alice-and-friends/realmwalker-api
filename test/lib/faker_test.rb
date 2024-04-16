# frozen_string_literal: true

require 'test_helper'

class FakerTest < ActiveSupport::TestCase
  test 'should generate djinn name' do
    djinn_name = Faker::Name.djinn_male_name
    assert djinn_name.present?
  end
end
