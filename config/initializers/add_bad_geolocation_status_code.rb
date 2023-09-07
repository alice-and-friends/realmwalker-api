# frozen_string_literal: true

# Docs: https://www.ietf.org/archive/id/draft-thomson-geopriv-http-geolocation-00.html

Rack::Utils::SYMBOL_TO_STATUS_CODE[:bad_geolocation] = 427
Rack::Utils::HTTP_STATUS_CODES[427] = 'Bad GeoLocation'
