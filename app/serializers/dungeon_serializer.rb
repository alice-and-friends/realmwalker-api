# frozen_string_literal: true

class DungeonSerializer < RealmLocationSerializer
  attributes :level
  belongs_to :monster
end
