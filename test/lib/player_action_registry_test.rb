# frozen_string_literal: true

require 'test_helper'

class PlayerActionRegistryTest < ActiveSupport::TestCase
  def valid_action
    {
      id: 'slash',
      type: 'attack',
      label: 'Slash Attack',
      damageTypes: ['slashing']
    }
  end

  def with_mocked_registry(actions)
    original = PlayerActionRegistry.method(:actions)
    PlayerActionRegistry.define_singleton_method(:actions) { actions }
    yield
  ensure
    PlayerActionRegistry.define_singleton_method(:actions, original)
  end

  test 'passes with a valid registry' do
    with_mocked_registry([valid_action]) do
      assert_nothing_raised { PlayerActionRegistry.validate! }
    end
  end

  test 'fails on missing :id' do
    broken = valid_action.except(:id)

    with_mocked_registry([broken]) do
      assert_raises(RuntimeError) do
        PlayerActionRegistry.validate!
      end
    end
  end

  test 'fails on missing :type' do
    broken = valid_action.except(:type)

    with_mocked_registry([broken]) do
      assert_raises(RuntimeError) do
        PlayerActionRegistry.validate!
      end
    end
  end

  test 'fails on missing :label' do
    broken = valid_action.except(:label)

    with_mocked_registry([broken]) do
      assert_raises(RuntimeError) do
        PlayerActionRegistry.validate!
      end
    end
  end

  test 'fails on unknown damageTypes' do
    broken = valid_action.merge(damageTypes: ['banana'])

    with_mocked_registry([broken]) do
      assert_raises(RuntimeError) do
        PlayerActionRegistry.validate!
      end
    end
  end

  test 'fails on duplicate IDs' do
    dup1 = valid_action.dup
    dup2 = valid_action.dup

    with_mocked_registry([dup1, dup2]) do
      assert_raises(RuntimeError) do
        PlayerActionRegistry.validate!
      end
    end
  end
end
