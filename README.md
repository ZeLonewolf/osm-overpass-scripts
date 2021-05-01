# osm-overpass-scripts
Shell scripts for manipulating OpenStreetMap overpass queries

Currently, these scripts only handle river/riverbank comparison.  However, the intent is to build up a library of generic scripts that can be used for tag comparisons and statistics generation.

Usage:

	./country_list.sh <overpass server url> | tee <output file>.csv
