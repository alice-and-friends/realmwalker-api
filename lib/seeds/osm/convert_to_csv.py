import sys
import osmium as o
import csv
import json
import math
import time
from geopy.distance import geodesic

geojsonfab = o.geom.GeoJSONFactory()

# Define the CSV headers
CSV_HEADERS = ["ext_id", "coordinates", "tags"]

class GeoJsonWriter(o.SimpleHandler):
    def __init__(self, output_file):
        super().__init__()
        self.output_file = output_file
        self.csv_writer = csv.writer(output_file)
        self.first = True

        # Store the coordinates of previously added points
        self.previous_coordinates = []

    def is_desirable(self, obj):
        # Tag categories
        amenity_tags = ['college', 'kindergarten', 'library', 'research_institute', 'music_school',
                        'school', 'place_of_worship', 'traffic_park', 'university', 'fuel', 'bank',
                        'arts_centre', 'cinema', 'community_centre', 'conference_centre', 'events_venue',
                        'exhibition_centre', 'fountain', 'planetarium', 'public_bookcase', 'social_centre',
                        'theatre', 'courthouse', 'ranger_station', 'townhall', 'clock', 'marketplace',
                        'public_bath', 'public_building']
        historic_tags = ['aqueduct', 'archaeological_site', 'battlefield', 'bomb_crater', 'boundary_stone',
                         'building', 'castle', 'church', 'city_gate', 'fort', 'milestone', 'monastery',
                         'monument', 'mosque', 'ogham_stone', 'ruins', 'rune_stone', 'stone', 'tower']
        man_made_tags = ['communications_tower', 'lighthouse', 'obelisk', 'observatory', 'pier',
                         'telescope', 'torii', 'tower', 'windmill']
        memorial_tags = ['war_memorial', 'statue', 'bust', 'stele', 'stone', 'obelisk', 'sculpture']
        tourism_tags = ['alpine_hut', 'aquarium', 'artwork', 'attraction', 'camp_pitch', 'camp_site',
                        'caravan_site', 'gallery', 'hostel', 'hotel', 'motel', 'museum', 'picnic_site',
                        'theme_park', 'viewpoint', 'wilderness_hut']

        tag_categories = {
            'amenity': amenity_tags,
            'historic': historic_tags,
            'man_made': man_made_tags,
            'memorial': memorial_tags,
            'tourism': tourism_tags
        }

        for category, tags in tag_categories.items():
            if category in obj.tags and obj.tags[category] in tags:
                return True
        return False

    def process_object(self, obj, coordinates, tags):
        # Check if the point is in the test area
        if not (56.63 < coordinates[0] < 60.00 and 10.40 < coordinates[1] < 12.94):
            return

        row = [
            obj.id,
            f"{coordinates[0]} {coordinates[1]}"
        ]

        tag_dict = dict((tag.k, tag.v) for tag in tags)
        tag_string = ';'.join([f"{key}:{value}" for key, value in tag_dict.items()]).replace('\n', ' ')
        row.append(tag_string)
        self.csv_writer.writerow(row)

    def node(self, o):
        if not self.is_desirable(o):
            return

        coordinates = (o.location.lat, o.location.lon)

        # Check for nearby points
        if self.has_points_nearby(coordinates, 1, 42.0):
            return
        if self.has_points_nearby(coordinates, 5, 300.0):
            return

        self.previous_coordinates.append(coordinates)
        self.process_object(o, coordinates, o.tags)

    def way(self, o):
        if not self.is_desirable(o):
            return

        try:
            first_node = next(o.nodes)
            coordinates = (first_node.lat, first_node.lon)
        except StopIteration:
            return

        self.process_object(o, coordinates, o.tags)

    def area(self, o):
        if not self.is_desirable(o):
            return

        try:
            first_node = next(o.outer_rings()[0].nodes)
            coordinates = (first_node.lat, first_node.lon)
        except (StopIteration, IndexError):
            return

        self.process_object(o, coordinates, o.tags)

    def progress(self, index):
        percent = int(index)/11150000000*100
        length = 25
        filledLength = int(percent/100*length)
        bar = '█' * filledLength + '-' * (length - filledLength)
        return f'|{bar}| {"%.2f" % round(percent, 2)}%'
        
    def print_progress(self, id, message):
        print(f'{self.progress(id)} {message}')

    def has_points_nearby(self, new_coordinates, num_points=1, min_distance=25.0):
        """
        Check if a new point is within the specified minimum distance of any existing points.

        Args:
            new_coordinates (tuple): Tuple of (latitude, longitude) for the new point.
            num_points (integer, optional): Tuple of (latitude, longitude) for the new point.
            min_distance (float, optional): The minimum distance threshold in meters.

        Returns:
            bool: True if the new point is at least the minimum distance from all existing points, False otherwise.
        """
        count = 0

        for coord in self.previous_coordinates:
            # Calculate the distance between the new point and the existing point
            distance = geodesic(new_coordinates, coord).meters

            # If the distance is less than the minimum distance, return True
            if distance < min_distance:
                count += 1
                if count == num_points:
                    return True

        # If the loop completes without finding a point that is too close, return False
        return False

def main(osmfile):
    with open("real_world_locations_osm.csv", "w", newline='') as f:  # Open in write mode to create a new CSV file
        handler = GeoJsonWriter(f)

        # Add a header row
        handler.csv_writer.writerow(CSV_HEADERS)

        handler.apply_file(osmfile)

    return 0

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python %s <osmfile>" % sys.argv[0])
        sys.exit(-1)
    sys.exit(main(sys.argv[1]))
