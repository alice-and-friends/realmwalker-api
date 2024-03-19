# frozen_string_literal: true

class DungeonSerializer < RealmLocationSerializer
  attributes :defeated_by, :monster

  def defeated_by
    ActiveModelSerializers::SerializableResource.new(object.defeated_by, each_serializer: SafeUserSerializer)
  end

  def monster
    ActiveModelSerializers::SerializableResource.new(object.monster, each_serializer: MonsterSerializer)
  end
end
