# frozen_string_literal: true

# Validates the PlayerActionRegistry at boot time to catch typos or invalid structures.
# If any action is misconfigured, an error is raised and Rails will fail to start.

Rails.application.config.to_prepare do
  PlayerActionRegistry.validate!
rescue StandardError => e
  Rails.logger.error "[StaticActionRegistry] Invalid combat action config: #{e.message}"
  raise e
end
