# osm-overpass-scripts
Shell scripts for manipulating OpenStreetMap overpass queries

Currently, these scripts only handle tag comparison.  However, the intent is to build up a library of generic scripts that can be used for tag comparisons and statistics generation.

Usage:

	./compare_tags_by_country.sh --server <overpass server url> --tag1 "waterway=river" --tag2 "water=river" --map <output file>.png
	./compare_tags_by_country.sh --server <overpass server url> --tag1 "waterway=river" --tag2 "water=river" --csv <output file>.csv

Requires:
* Rscript https://cran.r-project.org/

### Other options
* --throttle <number> - number of seconds to pause between overpass requests.  If you are running this against a private overpass instance, this can safely be set to zero to speed up processing.

## Installation

Install the following pre-requisites:
* R script (see installation instructions for: [Ubuntu 20.04](https://linuxize.com/post/how-to-install-r-on-ubuntu-20-04 "Ubuntu 20.04 R installation instructions"))
* libudunits2-dev

Run:

	sudo ./install.R
