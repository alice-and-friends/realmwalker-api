# frozen_string_literal: true

class Api::V1::HomeController < Api::V1::ApiController
  def home
    render json: {
      server_time: Time.current,
      events: events,
      locations: realm_locations,
    }
  end

  private

  def events
    # TODO: would be nice if @current_user_geolocation was converted to a class. Could also have a method to get user's timezone
    timezone = DateTimeHelper.timezone_at_coordinates(@current_user_geolocation[:latitude], @current_user_geolocation[:longitude])
    {
      events_timezone: timezone,
      active: ActiveModelSerializers::SerializableResource.new(Event.active(timezone), each_serializer: EventSerializer),
      upcoming: ActiveModelSerializers::SerializableResource.new(Event.upcoming, each_serializer: EventSerializer),
    }
  rescue StandardError => e
    Rails.logger.error(e)
    {
      events_timezone: 'error',
      active: [],
      upcoming: [],
    }
  end

  def realm_locations
    # Activate the area around the player (spawn monsters and such)
    ActivePlayerArea.activate(@current_user_geolocation)

    # Get common locations (visible to all players)
    locations = RealmLocation.where.not(type: %w[Npc Dungeon]).player_vision_radius(@current_user_geolocation) +
                Npc.player_vision_radius(@current_user_geolocation).with_spook_status +
                Dungeon.where.not(status: Dungeon.statuses[:expired]).player_vision_radius(@current_user_geolocation)

    # Get personal locations (visible to this player)
    locations << @current_user.base if @current_user.base.present?

    # Mark locations as seen
    LocationRelevanceWorker.perform_async(
      locations.pluck(:real_world_location_id),
      RealWorldLocation.relevance_grades[:seen],
    )

    ActiveModelSerializers::SerializableResource.new(locations, each_serializer: RealmLocationSerializer)
  end
end
