# frozen_string_literal: true

module Faker
  class Name
    class << self
      def human_male_name
        fetch('name.djinn_male_name')
      end

      def human_female_name
        fetch('name.djinn_male_name')
      end

      def human_neutral_name
        fetch('name.djinn_male_name')
      end

      def djinn_male_name
        fetch('name.djinn_male_name')
      end

      def dwarf_male_name
        fetch('name.dwarf_male_name')
      end

      def dwarf_female_name
        fetch('name.dwarf_female_name')
      end

      def dwarf_neutral_name
        fetch('name.dwarf_neutral_name')
      end

      def elf_male_name
        fetch('name.elf_male_name')
      end

      def elf_female_name
        fetch('name.elf_female_name')
      end

      def elf_neutral_name
        fetch('name.elf_neutral_name')
      end

      def fox_male_name
        fetch('name.fox_male_name')
      end

      def fox_female_name
        fetch('name.fox_female_name')
      end

      def fox_neutral_name
        fetch('name.fox_neutral_name')
      end

      def goblin_male_name
        fetch('name.goblin_male_name')
      end

      def goblin_female_name
        fetch('name.goblin_female_name')
      end

      def goblin_neutral_name
        fetch('name.goblin_neutral_name')
      end

      def humanoid_male_name
        fetch('name.humanoid_male_name')
      end

      def humanoid_female_name
        fetch('name.humanoid_female_name')
      end

      def humanoid_neutral_name
        fetch('name.humanoid_neutral_name')
      end
    end
  end
end
