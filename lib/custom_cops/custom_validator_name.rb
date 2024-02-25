# frozen_string_literal: true

module RuboCop
  module Cop
    # Ensure custom validators to have prefix "must_"
    class UsePrefixForCustomValidator < RuboCop::Cop::Cop
      MSG = 'Add a prefix "must_" to custom validator names'

      CUSTOM_VALIDATOR_METHOD = :validate

      def on_send(node)
        method = method_name(node)

        return unless custom_validator_method?(method)

        first_argument_node = first_argument(node)

        add_offense(first_argument_node, location: :expression) if missing_prefix?(first_argument_node.value)
      end

      private

      def custom_validator_method?(method)
        method == CUSTOM_VALIDATOR_METHOD
      end

      def method_name(node)
        node.children[1]
      end

      def first_argument(node)
        node.arguments[0]
      end

      def missing_prefix?(custom_validator_name)
        !custom_validator_name.to_s.include?('must_')
      end
    end
  end
end