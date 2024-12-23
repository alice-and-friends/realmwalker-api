# frozen_string_literal: true

require 'test_helper'

class WritingTest < ActiveSupport::TestCase
  test 'should create and destroy writing' do
    assert_nothing_raised do
      writing = Writing.create!(body: 'unused writing')
      assert_not_nil writing.id
      writing.destroy!
    end
  end
  test 'should destroy writing when inventory item is destroyed' do
    user = generate_test_user
    user.give_starting_equipment
    inventory_item = user.inventory_items.first
    writing = Writing.create!(body: 'inscription')
    inventory_item.update(writing: writing)
    assert_equal 1, Writing.count
    inventory_item.destroy!
    assert_equal 0, Writing.count
  end
  test 'should not destroy writing attached to item' do
    user = generate_test_user
    user.give_starting_equipment
    inventory_item = user.inventory_items.first
    writing = Writing.create!(body: 'inscription')
    inventory_item.update(writing: writing)
    assert_equal 1, Writing.count
    assert_raise(Exception) do
      # should fail
      writing.destroy!
    end
    assert_equal 1, Writing.count
  end
  test 'should not destroy core content writing' do
    @writing = nil
    assert_nothing_raised do
      @writing = Writing.create!(
        body: 'lorem ipsum',
        core_content: true,
        )
    end
    assert_equal 1, Writing.count
    assert_raise(Exception) do
      # should fail
      @writing.destroy!
    end
    assert_equal 1, Writing.count
  end
  test 'should nullify writing when author is destroyed' do
    user = generate_test_user
    writing = Writing.create!(author: user, body: 'lorem ipsum')
    assert_equal user.id, writing.author_id
    user.destroy!
    assert_nil writing.reload.author_id
  end
end
