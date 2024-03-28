# frozen_string_literal: true

# lib/rubocop/cop/project_name/remove_redundant_status_ok.rb
require 'rubocop'

module RuboCop
  module Cop
    module Custom
      # Custom cop that checks for and auto-corrects redundant `status: :ok` in Rails controllers
      class RemoveRedundantStatusOk < Base
        extend AutoCorrector

        MSG = 'Remove redundant `status: :ok` since it is the default status.'

        def_node_matcher :redundant_status_ok?, <<~PATTERN
          (send nil? :render (hash <$(pair (sym :json) _) $(pair (sym :status) (sym :ok)) ...>))
        PATTERN

        def on_send(node)
          redundant_status_ok?(node) do |json_pair, status_pair|
            add_offense(status_pair, message: MSG) do |corrector|
              autocorrect(corrector, json_pair, status_pair)
            end
          end
        end

        private

        def autocorrect(corrector, json_pair, status_pair)
          # Include any whitespace and comma before `status: :ok`
          range_before_status = range_with_comma_before(status_pair)

          # Create a range to remove, adjusted to include preceding comma and whitespace if present
          range_to_remove = if range_before_status
                              range_before_status.begin.join(status_pair.loc.expression)
                            else
                              json_pair.loc.expression.join(status_pair.loc.expression)
                            end

          corrector.remove(range_to_remove)
        end

        # Helper method to find the range including the comma (and any whitespace) before the status: :ok part
        def range_with_comma_before(node)
          # Assuming `node` is the status_pair
          source_buffer = node.loc.expression.source_buffer
          range_begin = node.loc.expression.begin_pos

          # Search backwards from the beginning of the status_pair for a comma
          comma_pos = source_buffer.source.rindex(',', range_begin - 1)
          return nil unless comma_pos

          # Create a range from the comma position to the start of the status_pair, including any whitespace
          Parser::Source::Range.new(source_buffer, comma_pos, range_begin)
        end
      end
    end
  end
end


