# frozen_string_literal: true

class DungeonSerializer < RealmLocationSerializer
  attributes :defeated_by

  def defeated_by
    ActiveModelSerializers::SerializableResource.new(object.defeated_by, each_serializer: SafeUserSerializer)
  end
end
