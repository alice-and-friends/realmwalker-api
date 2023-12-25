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

    def node(self, o):
        if o.tags:
            if 'fixme' in o.tags:
                # self.print_progress(o.id, "bad data")
                return  # Skip this node

            if 'access' in o.tags and o.tags['access'] != 'yes':
                # self.print_progress(o.id, "inaccessible")
                return  # Skip this node

            amenity_tags = ['college', 'kindergarten', 'library', 'research_institute', 'music_school', 'school', 'place_of_worship', 'traffic_park', 'university', 'fuel', 'bank', 'arts_centre', 'cinema', 'community_centre', 'conference_centre', 'events_venue', 'exhibition_centre', 'fountain', 'planetarium', 'public_bookcase', 'social_centre', 'theatre', 'courthouse', 'ranger_station', 'townhall', 'clock', 'marketplace', 'public_bath', 'public_building']
            historic_tags = ['aqueduct', 'archaeological_site', 'battlefield', 'bomb_crater', 'boundary_stone', 'building', 'castle', 'church', 'city_gate', 'fort', 'milestone', 'monastery', 'monument', 'mosque', 'ogham_stone', 'ruins', 'rune_stone', 'stone', 'tower']
            man_made_tags = ['communications_tower', 'lighthouse', 'obelisk', 'observatory', 'pier', 'telescope', 'torii', 'tower', 'windmill']
            memorial_tags = ['war_memorial', 'statue', 'bust', 'stele', 'stone', 'obelisk', 'sculpture']
            tourism_tags = ['alpine_hut', 'aquarium', 'artwork', 'attraction', 'camp_pitch', 'camp_site', 'caravan_site', 'gallery', 'hostel', 'hotel', 'motel', 'museum', 'picnic_site', 'theme_park', 'viewpoint', 'wilderness_hut']

            if 'amenity' in o.tags and o.tags['amenity'] in amenity_tags:
                self.print_object(o, geojsonfab.create_point(o), o.tags)
                return

            if 'historic' in o.tags and o.tags['historic'] in historic_tags:
                self.print_object(o, geojsonfab.create_point(o), o.tags)
                return

            if 'man_made' in o.tags and o.tags['man_made'] in man_made_tags:
                self.print_object(o, geojsonfab.create_point(o), o.tags)
                return

            if 'memorial' in o.tags and o.tags['memorial'] in memorial_tags:
                self.print_object(o, geojsonfab.create_point(o), o.tags)
                return

            if 'tourism' in o.tags and o.tags['tourism'] in tourism_tags:
                self.print_object(o, geojsonfab.create_point(o), o.tags)
                return

            # self.print_progress(o.id, "undesirable")

    def progress(self, index):
        percent = int(index)/11150000000*100
        length = 25
        filledLength = int(percent/100*length)
        bar = '█' * filledLength + '-' * (length - filledLength)
        return f'|{bar}| {"%.2f" % round(percent, 2)}%'
        
    def print_progress(self, id, message):
        print(f'{self.progress(id)} {message}')

    def print_object(self, o, geojson, tags):
        geom = json.loads(geojson)
        if geom:
            coordinates = (geom['coordinates'][1], geom['coordinates'][0])

            # Check if the point is in the test area
            # if not (59.903 < coordinates[0] < 59.936 and 10.691 < coordinates[1] < 10.767): # Oslo
            # if not (59.65 < coordinates[0] < 60.00 and 10.40 < coordinates[1] < 11.13): # Oslo surroundings
            if not (56.63 < coordinates[0] < 60.00 and 10.40 < coordinates[1] < 12.94): # Oslo - Halmstad
                # print(f'out of bounds {self.progress(o.id)} @ {coordinates[1]}, {coordinates[0]}')
                return  # Skip this point

            # Check if the new point is within the minimum distance of previously added points
            if self.has_points_nearby(coordinates, 1, 42.0):
                self.print_progress(o.id, "too close to other point")
                return  # Skip this point
            if self.has_points_nearby(coordinates, 5, 300.0):
                self.print_progress(o.id, "too many points in immediate area")
                return  # Skip this point

            # Add the new point to the list of previously added points
            self.previous_coordinates.append(coordinates)

            row = [
                o.id,
                f"{coordinates[0]} {coordinates[1]}"
            ]

            # Convert tags (TagList) to a dictionary
            tag_dict = dict((tag.k, tag.v) for tag in tags)

            # Convert the dictionary to a semicolon-separated string
            tag_string = ';'.join([f"{key}:{value}" for key, value in tag_dict.items()]).replace('\n', ' ')
            row.append(tag_string)  # Append the tag_string to the row
            self.print_progress(o.id, row)

            self.csv_writer.writerow(row)  # Write the row to the CSV file

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
