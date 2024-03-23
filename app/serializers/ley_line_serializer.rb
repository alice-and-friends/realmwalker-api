# frozen_string_literal: true

class LeyLineSerializer < RealmLocationSerializer
  attributes :captured_at, :owner

  def owner
    return nil if object.owner.nil?

    {
      name: object.owner.name,
    }
  end
end
