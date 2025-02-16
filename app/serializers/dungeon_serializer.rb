# frozen_string_literal: true

class DungeonSerializer < RealmLocationSerializer
  attributes :hp, :defeated_by, :monster
  attribute :searchable, if: :user
  attribute :already_searched, if: :user

  def defeated_by
    ActiveModelSerializers::SerializableResource.new(object.defeated_by, each_serializer: SafeUserSerializer)
  end

  def monster
    ActiveModelSerializers::SerializableResource.new(object.monster, each_serializer: MonsterSerializer)
  end

  def searchable
    object.defeated? && !already_searched
  end

  def already_searched
    user.searched_dungeon? object
  end

  def user
    instance_options[:user]
  end
end
