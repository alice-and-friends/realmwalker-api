# frozen_string_literal: true

module LockedTransaction
  def locked_transaction(seconds = 2, &block)
    self.class.transaction do
      self.class.connection.execute("SET LOCAL lock_timeout = '#{seconds}s'")
      with_lock(&block)
    end
  end
end
