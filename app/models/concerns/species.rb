# frozen_string_literal: true

module Species
  extend ActiveSupport::Concern
  included do
    SPECIES = %w[human elf dwarf giant troll goblin kenku djinn].freeze
  end
end
