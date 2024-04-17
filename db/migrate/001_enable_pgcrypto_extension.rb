# frozen_string_literal: true

class EnablePgcryptoExtension < ActiveRecord::Migration[7.0]
  def self.up
    enable_extension 'pgcrypto'
  end

  def self.down
    disable_extension 'pgcrypto'
  end
end
