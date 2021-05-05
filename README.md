# osm-overpass-scripts
Shell scripts for manipulating OpenStreetMap overpass queries

Currently, these scripts only handle tag comparison.  However, the intent is to build up a library of generic scripts that can be used for tag comparisons and statistics generation.

## compare_tags_by_country.sh
| green-red | viridis | plasma | blue-red |
| --------- | ------- | ------ | -------- |
| <img src="https://github.com/ZeLonewolf/osm-overpass-scripts/blob/main/img/test1.png" width="170"> | <img src="https://github.com/ZeLonewolf/osm-overpass-scripts/blob/main/img/test2.png" width="170"> | <img src="https://github.com/ZeLonewolf/osm-overpass-scripts/blob/main/img/test3.png" width="170"> | <img src="https://github.com/ZeLonewolf/osm-overpass-scripts/blob/main/img/test4.png" width="170"> |

Usage:

	./compare_tags_by_country.sh --server <overpass server url> --tag1 "waterway=river" --tag2 "water=river" --map <output file>.png
	./compare_tags_by_country.sh --server <overpass server url> --tag1 "waterway=river" --tag2 "water=river" --csv <output file>.csv

Requires:
* R for map plotting https://cran.r-project.org/ see Installation.

### Parameters
    --server            - url to overpass server (default: http://lz4.overpass-api.de)
    --tag1              - subject tag for percent of usage calculation (default: waterway=river)
    --tag2              - tag for comparison (defalut: water=river)
    --csv               - output file for counts in csv format
    --map               - file name for map plot. Supported formats: .png, .jpg, .pdf
    --color             - color scheme for plot. [green-red: GR, blue-red: BR, viridis: V, plasma: P] (default: GR)
    --throttle <int>    - number of seconds to pause between overpass requests.  If you are running this against a private
                          overpass instance, this can safely be set to zero to speed up processing. (default: 5)

## Installation

Install the following pre-requisites:
* R script (see installation instructions for: [Ubuntu 20.04](https://linuxize.com/post/how-to-install-r-on-ubuntu-20-04 "Ubuntu 20.04 R installation instructions"))
* libudunits2-dev

Run:

	sudo ./install.R
