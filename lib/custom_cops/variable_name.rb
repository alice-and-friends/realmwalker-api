# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # Custom cop that disallows certain variable names
      class VariableName < Base
        extend AutoCorrector

        MSG = 'Avoid using variable name `%<variable_name>s`. Use `%<suggestion>s` instead.'

        # Define a mapping of disallowed variable names to suggestions
        DISALLOWED_VARIABLES = {
          'lat' => 'latitude',
          'lon' => 'longitude',
          'lng' => 'longitude',
          'coordinate' => 'coordinates',
          # Add more disallowed variables and suggestions here
        }.freeze

        def on_lvasgn(node)
          variable_name, = *node
          check_variable_name(node, variable_name.to_s)
        end

        private

        def check_variable_name(node, variable_name)
          suggestion = DISALLOWED_VARIABLES[variable_name]
          return unless suggestion

          message = format(MSG, variable_name: variable_name, suggestion: suggestion)
          add_offense(node, message: message) do |corrector|
            corrector.replace(node.loc.name, suggestion)
          end
        rescue => e
          puts "Error processing node: #{e.message}"
        end
      end
    end
  end
end
