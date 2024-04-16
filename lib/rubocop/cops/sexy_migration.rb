# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      class UseSexyMigrationSyntax < RuboCop::Cop::Cop
        MSG = 'Prefer using shorthand syntax for column definitions.'

        def on_send(node)
          if column_method_usage?(node)
            # Only add an offense since the autocorrect functionality has been removed.
            add_offense(node, message: MSG)
          end
        end

        private

        # Check if the node represents a `column` method call with at least two arguments
        # where the first is a symbol (the column name) and the second is a symbol (the column type).
        # This method does not account for additional options or arguments.
        def column_method_usage?(node)
          # Check if the method name is :column and it has at least two arguments
          return false unless node.method_name == :column && node.arguments.size >= 2

          # Ensure the first two arguments are symbols (for column name and type)
          first_arg, second_arg = node.arguments
          first_arg.type == :sym && second_arg.type == :sym
          # You could add additional checks here for further arguments if necessary
        end
      end
    end
  end
end
