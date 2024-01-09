import sys
import osmium as o
import csv
import time
from geopy.distance import geodesic
import shapely.wkb as wkblib

wkbfab = o.geom.WKBFactory()

# Define the CSV headers
CSV_HEADERS = ["ext_id", "coordinates", "tags"]


class CoordinatesManager:
    def __init__(self, max_length=10_000):
        self.max_length = max_length
        self.previous_coordinates = []
        self.previous_node_coordinates = []

    def size(self):
        return len(self.previous_node_coordinates)

    def append(self, coordinates, item_type='node'):
        self.previous_coordinates.append(coordinates)

        if item_type == 'node':
            if len(self.previous_node_coordinates) >= self.max_length:
                self.previous_node_coordinates.pop(0)
            self.previous_node_coordinates.append(coordinates)

    def has(self, coordinates):
        return coordinates in self.previous_coordinates

    def has_nodes_nearby(self, new_coordinates, num_points=1, min_distance=25.0):
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

        for coord in self.previous_node_coordinates:
            # Calculate the distance between the new point and the existing point
            distance = geodesic(new_coordinates, coord).meters

            # If the distance is less than the minimum distance, return True
            if distance < min_distance:
                count += 1
                if count == num_points:
                    return True

        # If the loop completes without finding a point that is too close, return False
        return False


class CSVWriter(o.SimpleHandler):
    def __init__(self, output_file):
        super().__init__()
        self.coordinates_manager = CoordinatesManager()
        self.output_file = output_file
        self.csv_writer = csv.writer(output_file)
        self.first = True

        self.c_node = 0
        self.c_way = 0
        self.c_area = 0
        self.id_node = 1
        self.id_way = 1

    def is_desirable(self, obj):
        # osmium tags-filter planet-230828.osm.pbf amenity historic leisure man_made memorial tourism -o planet-filtered.osm.pbf --overwrite

        if 'fixme' in obj.tags:
            return False  # Skip this node

        if 'access' in obj.tags and obj.tags['access'] != 'yes':
            return False  # Skip this node

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
        leisure_tags = ['amusement_arcade', 'dog_park', 'firepit', 'ice_rink', 'park',
                        'sports_centre', 'sports_hall', 'stadium', 'water_park']
        man_made_tags = ['communications_tower', 'lighthouse', 'obelisk', 'observatory',
                         'telescope', 'torii', 'tower', 'windmill']
        memorial_tags = ['war_memorial', 'statue', 'bust', 'stele', 'stone', 'obelisk', 'sculpture']
        tourism_tags = ['alpine_hut', 'aquarium', 'artwork', 'attraction', 'camp_pitch', 'camp_site',
                        'caravan_site', 'gallery', 'hostel', 'hotel', 'motel', 'museum', 'picnic_site',
                        'theme_park', 'viewpoint', 'wilderness_hut']

        tag_categories = {
            'amenity': amenity_tags,
            'historic': historic_tags,
            'leisure': leisure_tags,
            'man_made': man_made_tags,
            'memorial': memorial_tags,
            'tourism': tourism_tags
        }

        for category, tags in tag_categories.items():
            if category in obj.tags and obj.tags[category] in tags:
                return True
        return False

    def process_object(self, obj, coordinates, tags):
        row = [
            obj.id,
            f"{coordinates[0]} {coordinates[1]}"
        ]

        tag_dict = dict((tag.k, tag.v) for tag in tags)
        tag_string = ';'.join([f"{key}:{value}" for key, value in tag_dict.items()]).replace('\n', ' ')
        row.append(tag_string)
        self.csv_writer.writerow(row)

        if obj.id % 25 == 0:
            self.print_progress(obj.id)

    def node(self, o):
        if not self.is_desirable(o):
            return

        coordinates = (o.location.lat, o.location.lon)
        if self.coordinates_manager.has(coordinates):
            return

        # Check for nearby points
        if self.coordinates_manager.has_nodes_nearby(coordinates, 1, 42.0):
            return
        if self.coordinates_manager.has_nodes_nearby(coordinates, 4, 400.0):
            return

        self.id_node = o.id
        self.c_node += 1
        self.coordinates_manager.append(coordinates, item_type='node')
        self.process_object(o, coordinates, o.tags)

    def way(self, o):
        # if o.is_closed():
        #    return  # It's probably an area?

        if not self.is_desirable(o):
            return

        try:
            first_node = o.nodes[0]
            coordinates = (first_node.lat, first_node.lon)
        except StopIteration:
            return

        if self.coordinates_manager.has(coordinates):
            return

        # Check for nearby points
        if self.coordinates_manager.has_nodes_nearby(coordinates, 1, 245.0):
            return
        if self.coordinates_manager.has_nodes_nearby(coordinates, 2, 300.0):
            return

        self.id_way = o.id
        self.c_way += 1
        self.coordinates_manager.append(coordinates, item_type='way')
        self.process_object(o, coordinates, o.tags)

    def area(self, o):
        return

        # if not self.is_desirable(o):
        #     return
        #
        # try:
        #     wkb = wkbfab.create_multipolygon(o)
        #     poly = wkblib.loads(wkb, hex=True)
        #     centroid = poly.representative_point()
        #     coordinates = (centroid.x, centroid.y)
        # except (StopIteration, IndexError, RuntimeError) as e:
        #     print(f"Encountered an error with area_id={o.id}: {e}")
        #     return
        #
        # if self.coordinates_manager.has(coordinates):
        #     return
        #
        # # Check for nearby points
        # if self.coordinates_manager.has_points_nearby(coordinates, 1, 500.0):
        #     return
        # if self.coordinates_manager.has_points_nearby(coordinates, 2, 4000.0):
        #     return
        #
        # self.c_area += 1
        # self.coordinates_manager.append(coordinates, item_type='area')
        # self.process_object(o, coordinates, o.tags)

    def progress_bar(self, index, total):
        percent = int(index) / total * 100
        length = 25
        filledLength = int(percent / 100 * length)
        bar = '█' * filledLength + '-' * (length - filledLength)
        return f'|{bar}| {"%.2f" % round(percent, 2)}%'

    def print_progress(self, id):
        x_node = 11149219605
        x_way = 1202659334
        print(
            f"{self.progress_bar(self.id_node + self.id_way, x_node + x_way)} : {self.c_node} nodes, {self.c_way} ways, {self.c_area} areas, {self.coordinates_manager.size()} nodes in buffer",
            end='\r')
        return

        print("{} {}/{} nodes, {} {}/{} ways".format(
            self.progress_bar(self.c_node, x_node), self.c_node, x_node,
            self.progress_bar(self.c_way, x_way), self.c_way, x_way,
        ), end='\r')


def main(osmfile):
    with open("real_world_locations_osm.csv", "w", newline='') as f:  # Open in write mode to create a new CSV file
        handler = CSVWriter(f)

        print('Parsing file...')
        time_start = time.perf_counter()

        handler.csv_writer.writerow(CSV_HEADERS)
        handler.apply_file(osmfile)

        time_end = time.perf_counter()
        time_duration = time_end - time_start
        print(
            f"\nDone! {handler.c_node + handler.c_way + handler.c_area} ({handler.c_node}+{handler.c_way}+{handler.c_area}) locations in {time_duration:.3f} seconds")

    return 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python %s <osmfile>" % sys.argv[0])
        sys.exit(-1)
    sys.exit(main(sys.argv[1]))
