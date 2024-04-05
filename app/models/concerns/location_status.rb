# frozen_string_literal: true

module LocationStatus
  extend ActiveSupport::Concern
  class_methods do
    # ...
  end
  included do
    enum status: { active: 'active', defeated: 'defeated', expired: 'expired' }

    before_validation :set_active_status, on: :create

    scope :visible, -> { where(status: [statuses[:active], statuses[:defeated]]) }

    def set_active_status
      self.status = self.class.statuses[:active] if status.nil?
    end
  end
end
