# frozen_string_literal: true

class Runestone < RealmLocation
  validates :name, :runestone_id, presence: true
  validate :must_have_valid_runestone_id

  before_validation :set_region_and_coordinates!, on: :create

  def author
    RunestonesHelper.find(runestone_id).text
  end

  def text
    RunestonesHelper.find(runestone_id).text
  end

  private

  def must_have_valid_runestone_id
    errors.add(:runestone_id, 'not a valid runestone ID') unless RunestonesHelper.exists?(runestone_id)
  end
end
