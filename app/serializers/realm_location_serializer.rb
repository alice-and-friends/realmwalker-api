class RealmLocationSerializer < ActiveModel::Serializer
  attributes :id, :location_type, :name, :coordinates
  attribute :dungeon_details, if: :dungeon?

  def dungeon?
    object.location_type == Dungeon.name
  end
  def dungeon_details
    {
      level: object.level,
      monster_classification: object.monster.classification,
    }
  end
end
