import csv
import sys

# Function to create a second CSV file with every 10th line
def create_second_file(input_file, output_file):
    with open(input_file, 'r', newline='') as input_csv, open(output_file, 'w', newline='') as output_csv:
        reader = csv.reader(input_csv)
        writer = csv.writer(output_csv)

        # Write the header row to the second file
        header = next(reader)
        writer.writerow(header)

        # Write every 10th line to the second file
        for i, row in enumerate(reader):
            if i % 10 == 0:
                writer.writerow(row)

# Function to create a third CSV file with coordinates within bounds
def create_third_file(input_file, output_file):
    with open(input_file, 'r', newline='') as input_csv, open(output_file, 'w', newline='') as output_csv:
        reader = csv.reader(input_csv)
        writer = csv.writer(output_csv)

        # Write the header row to the third file
        header = next(reader)
        writer.writerow(header)

        # Write lines with coordinates within specified bounds
        for row in reader:
            coordinates = row[1]  # Assuming the coordinates column is in the second position
            lat, lon = map(float, coordinates.split())

            if 59 < lat < 60 and 10 < lon < 11:
                writer.writerow(row)

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: python shrink.py real_world_locations_osm.csv real_world_locations_osm_short.csv real_world_locations_osm_bounded.csv")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file1 = sys.argv[2]
    output_file2 = sys.argv[3]

    create_second_file(input_file, output_file1)
    create_third_file(input_file, output_file2)

    print(f'Second file created: {output_file1}')
    print(f'Third file created: {output_file2}')
