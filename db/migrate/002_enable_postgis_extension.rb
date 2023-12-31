# frozen_string_literal: true

class EnablePostgisExtension < ActiveRecord::Migration[7.0]
  def self.up
    enable_extension 'postgis'
  end

  def self.down
    disable_extension 'postgis'
  end
end
