# frozen_string_literal: true

module Species
  extend ActiveSupport::Concern

  included do
    SPECIES = %w[elf djinn dwarf fox giant goblin human kenku troll ].freeze
  end

  DISTRIBUTION = {
    'default' => [
      ['human', 64],
      ['elf', 10],
      ['giant', 5],
      ['dwarf', 5],
      ['troll', 5],
      ['goblin', 5],
      ['kenku', 5],
      ['djinn', 1],
    ],
    'alchemist' => [
      ['human', 89],
      ['elf', 5],
      ['kenku', 5],
      ['djinn', 1],
    ],
    'castle' => [
      ['human', 80],
      ['dwarf', 15],
      ['kenku', 5],
    ],
    'druid' => [
      ['human', 45],
      ['elf', 45],
      ['djinn', 5],
      ['fox', 5],
    ],
  }.freeze
end
