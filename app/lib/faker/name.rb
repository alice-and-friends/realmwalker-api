# frozen_string_literal: true

module Faker
  class Name
    class << self
      def djinn_name
        fetch('name.djinn_name')
      end
    end
  end
end
