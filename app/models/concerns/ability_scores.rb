# frozen_string_literal: true

module AbilityScores
  extend ActiveSupport::Concern

  ABILITY_SCORE_BASE = 8
  MAX_IMPROVEMENTS_PER_TYPE = 8

  included do
    enum ability: {
      vitality: 'VIT',
      strength: 'STR',
      dexterity: 'DEX',
      perception: 'PER',
      luck: 'LUC',
    }

    validates :ability_score_improvements, inclusion: { in: User.abilities.values }
    validate :must_be_valid_asi
    validate :must_not_exceed_asi_limitations

    def asi_allotment
      (level / 5).floor
    end

    def exceeds_asi_allotment?
      ability_score_improvements.count > asi_allotment
    end

    def improve_ability!(ability_key)
      raise "#{ability} is not a valid ability" unless ability_key.in? User.abilities.values

      ability_score_improvements << ability_key
      save!
      ability_scores
    end

    def ability_scores
      list = []
      User.abilities.each do |name, key|
        improvements = ability_score_improvements.filter_map do |asi|
          asi if asi == key
        end
        list << {
          key: key,
          name: name.capitalize,
          value: ABILITY_SCORE_BASE + improvements.count,
          base: ABILITY_SCORE_BASE,
          improvements: improvements.count,
        }
      end
      list
    end

    def ability_score(ability_key)
      raise "#{ability_key} is not a valid ability" unless ability_key.in? User.abilities.values

      improvements = ability_score_improvements.filter_map do |asi|
        asi if asi == ability_key
      end

      ABILITY_SCORE_BASE + improvements.count
    end

    private

    # Removes the most recently added Ability Score Improvement(s), if allotment is exceeded
    def trim_ability_score_improvements
      ability_score_improvements.pop while exceeds_asi_allotment?

      ability_score_improvements
    end

    def must_be_valid_asi
      # Should have only valid types
      ability_score_improvements.each do |asi|
        errors.add(:ability_score_improvements, "contains an invalid type '#{asi}'") unless asi.in? User.abilities.values
      end
    end

    def must_not_exceed_asi_limitations
      errors.add(:ability_score_improvements, "exceeds maximum of #{asi_allotment}") if exceeds_asi_allotment?
    end
  end
end
