#!/usr/bin/env python3
# ./compare_tags_by_country.sh  --tag1 waterway=riverbank --tag2 water=river --map test2.png --server http://lz4.overpass-api.de --csv tag_compare.csv

import requests
import sys
import datetime
import argparse
import json
import time
import csv

parser = argparse.ArgumentParser(description='Script for getting per-country tag counts via taginfo. Quicker alternative to compare_tags_by_country.sh')
"""
#defaults
server=${server:-"http://lz4.overpass-api.de"}
tag1=${tag1:-"waterway=riverbank"}
tag2=${tag2:-"water=river"}
color=${color:-"GR"}
tmpcsv="/tmp/all_country_ids.csv"
throttle=${throttle:-1}

#color output codes
YELLOW='\033[1;33m'
NC='\033[0m'
"""

parser.add_argument('--server', type=str, help='Does nothing')
parser.add_argument('-o', '--output', type=str,  metavar='FILE',
                    help='Outputfile for plot (.png, ,jpg, .pdf)',
                    default="plot_" + str(datetime.datetime.now()) + ".png")
parser.add_argument('--tag1', type=str, help='tag name', default="waterway=riverbank")
parser.add_argument('--tag2', type=str, help='tag name', default="water=river")
parser.add_argument('--level', type=int, help='Admin level (0..4)', default="2")
parser.add_argument('--color', type=str, help='Map color scale', default="GR")
parser.add_argument('--csv', type=str,  metavar='FILE', required=False, default=None)
parser.add_argument('--map', type=str,  metavar='FILE', required=False, default=None)

args = parser.parse_args()

with open('OSM_regions.json') as f:
    regions = json.load(f)


def recursive_regions(regions, max_lvl=args.level):
    output = []
    is_rus = int(regions['name'] == "Russia")
    # Since russia is so large, taginfo server treats it as separate continent.
    if regions['admin_level'] >= max_lvl-is_rus or not regions['subregions']:
        iso = None
        if 'iso' in regions:
            iso = regions['iso']
        return [(regions['name'], iso, regions['taginfo_url'])]
    for region in regions['subregions']:
        output += recursive_regions(region, max_lvl)
    return output


# Process regions.json file. Recursively iterates over the tree and
# returns list of taginfo servers to scan, in format (name, server_url)
list_of_taginfo_servers = recursive_regions(regions, args.level)

dict_of_country_codes = dict()
f = csv.reader(open('sample list of countries.txt'))
for row in f:
    # Data sample: 53296,ME,Montenegro
    # print(row)
    rel_id, iso, name = row
    dict_of_country_codes[name] = iso


print("processing $csvlines countries")
print(f"@[iso,name]: {args.tag1}, {args.tag2}")
print("------------------------------")

# iso_a2 must be present because it's used for R mapping.
output = [f"iso_a2,name,{args.tag1},{args.tag2}"]
for region, iso, server in list_of_taginfo_servers:
    if '=' in args.tag1:
        url1 = server+'/api/4/tag/stats'
        params1 = {'key': args.tag1.split('=')[0],
                   'value': '='.join(args.tag1.split('=')[1:])}
    else:
        url1 = server+'/api/4/key/stats'
        params1 = {'key': args.tag1}
    if '=' in args.tag2:
        url2 = server+'/api/4/tag/stats'
        params2 = {'key': args.tag2.split('=')[0],
                   'value': '='.join(args.tag2.split('=')[1:])}
    else:
        url2 = server+'/api/4/key/stats'
        params2 = {'key': args.tag2}
    req_ok = False
    failures = 1
    while not req_ok:
        resp1 = requests.get(url1, params1)
        resp2 = requests.get(url2, params2)
        if resp1.status_code != 200 or resp2.status_code != 200:
            # print(resp1.content)
            # print(resp2.content)
            time.sleep(0.25*failures)
        else:
            req_ok = True
        failures += 1
        if failures % 4 == 0:
            print(f'Trying to contact taginfo at {url1}, attempt {failures}.')

    count1 = list(filter(lambda x: x['type'] == 'all', resp1.json()['data']))[0]['count']
    count2 = list(filter(lambda x: x['type'] == 'all', resp2.json()['data']))[0]['count']
    print(f"[{iso} {region}]: {count1}, {count2}")
    if not iso:
        iso = 'FIXME'
        # Possible alternative to fix those fixmes: run overpass query for only those regions
    else:  # FIXME: Temp workaround to missing iso codes
        output.append(f"{iso},{region}, {count1}, {count2}")
    # There's nothing more permanent, than temporary solution.
    time.sleep(0.05)
with open("/tmp/tags_all_countries.csv", 'w') as tmpcsv:
    print('\n'.join(output), file=tmpcsv)
if args.csv:
    with open(args.csv, 'w') as csv:
        print('\n'.join(output), file=csv)
