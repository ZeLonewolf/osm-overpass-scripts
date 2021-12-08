# osm-overpass-scripts
Shell scripts for manipulating OpenStreetMap overpass queries

The intent of this repository is to build up a library of generic scripts that can be used for tag comparisons and statistics generation using overpass.

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
    --tag1              - subject tag for percent of usage calculation (default: waterway=riverbank)
    --tag2              - tag for comparison (defalut: water=river)
    --csv               - output file for counts in csv format
    --map               - file name for map plot. Supported formats: .png, .jpg, .pdf
    --color             - color scheme for plot. [green-red: GR, blue-red: BR, viridis: V, plasma: P] (default: GR)
    --throttle <int>    - number of seconds to pause between overpass requests.  If you are running this against a private
                          overpass instance, this can safely be set to zero to speed up processing. (default: 1)

## get_tag_density_map.sh
| no borders | w/ borders |
| ----| ---- |
| <img src="https://github.com/ZeLonewolf/osm-overpass-scripts/blob/main/img/testdens1.png" width="350"> | <img src="https://github.com/ZeLonewolf/osm-overpass-scripts/blob/main/img/testdens2.png" width="350"> |

Usage:

    ./get_tag_density_map.sh --server <overpass server url> --tag "water=river" --map <output file>.png

### Parameters
     --server            - url to overpass server (default: http://lz4.overpass-api.de)
     --tag               - tag for object density analysis (default: waterway=riverbank)
     --csv               - output file for counts in csv format
     --map               - file name for map plot. Supported formats: .png, .jpg, .pdf
     --binwidth          - size of square for object counting in degrees. 1 means 1˚x1˚ square (default: 1)
     --bbox              - boundig box for area of analysis. minlat,minlon,maxlat,maxlon (default: whole world)
     --countries         - draw countries' borders [yes|no] (default: no)
     --location          - bbox area preset. [Europe, USA, Asia, Africa, NAmerica, SAmerica] (default: whole world)
     --plotbackend       - choose backed for plotting between R and python [R, py] (default: R)
     --throttle <int>    - number of seconds to pause between overpass requests. (default: 1)

Note: Some tag names need to be quoted e.g. `--tag \"name:etymology:wikidata\"`
Requires: R of python for plotting

## view_tag_history.sh
| single tag | two tags comparison |
| ----| ---- |
| <img src="https://github.com/ZeLonewolf/osm-overpass-scripts/blob/main/img/testhist1.png" width="350"> | <img src="https://github.com/ZeLonewolf/osm-overpass-scripts/blob/main/img/testhist2.png" width="350"> |

Usage:

    ./get_tag_density_map.sh --tag1 "water=river" [--tag2 "waterway=riverbank"] --plot <output file>.png --binwidth year [--csv yes]

### Parameters
     --tag1              - tag for object history analysis (default: waterway=riverbank)
     --tag1              - second tag for object history analysis (optional)
     --csv               - save tag history data as .csv files (default: off)
     --plot              - file name for plot. Supported formats: .png, .jpg, .pdf
     --binwidth          - timeinterval used for binning (year | quarter | month | week, default: day)

Note: Uses data from taginfo API

## Installation

Install the following pre-requisites:
* libudunits2-dev
* libfontconfig1-dev
* libicu66
* libcairo2-dev
* R script (see installation instructions for: [Ubuntu 20.04](https://linuxize.com/post/how-to-install-r-on-ubuntu-20-04 "Ubuntu 20.04 R installation instructions"), [Ubuntu 21.04](https://cran.r-project.org/bin/linux/ubuntu/)

Run:

	sudo ./install.R


For python:

     pip install numpy
     pip install matplotlib
     pip install geopandas

## Taginfo version
Usually you don't need newest country tag statistics for latest minute, but you would satisfy also with day or two old information. For such purpose this repo features `taginfo_compare_tags` scripts, which will use taginfo pages to get precompiled tag counts faster than any overpass could offer. Two scripts rely heavily on [[OSM_regions.json]] datafile, which namely contains information on *(almost)* all the Geofabrik's taginfo servers in structured manner. List has been compiled automatically, but information for some subregions and additional information were added manually. 

Using this version proceses ~150 countries in 30 seconds using taginfo, and remaining 45 in 12 minutes using overpass. Option to drop overpass is not implemented yet. Potential way to speed up overpass, is merge small countries into single overpass query.

TODO: Add plotting support for subregions. Support for subregions will need special treatment in R.
