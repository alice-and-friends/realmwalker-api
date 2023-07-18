class DungeonSerializer < RealmLocationSerializer
  attributes :level
  belongs_to :monster
end
