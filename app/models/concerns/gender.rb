# frozen_string_literal: true

module Gender
  extend ActiveSupport::Concern
  included do
    GENDERS = %w[f m x].freeze
  end
end
