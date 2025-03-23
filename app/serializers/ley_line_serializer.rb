# frozen_string_literal: true

class LeyLineSerializer < RealmLocationSerializer
  attributes :captured_at, :captured_by

  def captured_by
    # ActiveModelSerializers::SerializableResource.new(object.captured_by, each_serializer: UserSafeSerializer)
  end
end
