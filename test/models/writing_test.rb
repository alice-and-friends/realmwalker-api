# frozen_string_literal: true

require 'test_helper'

class WritingTest < ActiveSupport::TestCase
  setup do
    @user = generate_test_user
    @user.give_starting_equipment
    @inventory_item = @user.inventory_items.first
  end
  test 'should create and destroy writing' do
    writing = Writing.create!(body: 'unused writing')
    writing.destroy!
    assert writing.destroyed?
  end
  test 'should destroy writing (not core content) when inventory item is destroyed' do
    writing = Writing.create!(body: 'inscription', core_content: false)
    @inventory_item.update(writing: writing)
    @inventory_item.destroy!
    assert @inventory_item.destroyed?
    assert writing.destroyed?
  end
  test 'should not destroy writing attached to item' do
    writing = Writing.create!(body: 'weapon inscription')
    @inventory_item.update(writing: writing)
    assert_raise(ActiveRecord::RecordNotDestroyed) do
      # should fail
      writing.destroy!
    end
  end
  test 'should not destroy core content writing' do
    writing = Writing.create!(
      body: 'lorem ipsum',
      core_content: true,
    )
    assert_raise(ActiveRecord::RecordNotDestroyed) do
      # should fail
      writing.destroy!
    end
  end
  test 'should only destroy item, not attached core content' do
    writing = Writing.create!(body: 'book contents', core_content: true)
    @inventory_item.update(writing: writing)

    @inventory_item.destroy!
    assert @inventory_item.destroyed?
    assert writing.persisted?
  end
  test 'should nullify writing when author is destroyed' do
    writing = Writing.create!(author: @user, body: 'lorem ipsum')
    assert_equal @user.id, writing.author_id
    @user.destroy!
    assert_nil writing.reload.author_id
  end
end
