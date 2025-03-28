# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  include LockedTransaction

  scope :oldest, -> { order('created_at ASC').first }
  scope :newest, -> { order('created_at DESC').first }
end
