# frozen_string_literal: true

class RenewableGrowthWorker
  include Sidekiq::Job

  def perform
    Renewable.find_each(&:grow!)
    puts '♻️ Renewables increased'
    self.class.perform_at(Renewable.next_growth_at)
  end
end
