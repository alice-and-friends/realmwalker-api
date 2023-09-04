# frozen_string_literal: true

require 'test_helper'

class TradeOfferTest < ActiveSupport::TestCase
  test 'there are trade offers in the test database' do
    assert_operator TradeOffer.count, :>, 0
  end
end
