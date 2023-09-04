# frozen_string_literal: true

require 'test_helper'

class TradeOfferListTest < ActiveSupport::TestCase
  test 'there are trade offer lists in the test database' do
    assert_operator TradeOfferList.count, :>, 0
  end
end
