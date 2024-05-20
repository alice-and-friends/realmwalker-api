# frozen_string_literal: true

class LycanthropeExpirationWorker
  include Sidekiq::Job
  sidekiq_options queue: 'environment-normal'

  # Expire all werewolves and similar creatures relating to the Full Moon event
  def perform
    werewolf = Monster.find_by(name: 'Werewolf')
    Dungeon.where(monster_id: werewolf.id).find_each(&:schedule_expiration!)

    puts '🟠 Expired all werewolves.'
  end
end
