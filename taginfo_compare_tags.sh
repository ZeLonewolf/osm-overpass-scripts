#!/bin/bash

#command-line arguments
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done

#defaults
server=${server:-"http://lz4.overpass-api.de"}
tag1=${tag1:-"waterway=riverbank"}
tag2=${tag2:-"water=river"}
color=${color:-"GR"}
tmpcsv="/tmp/all_country_ids.csv"
tag_count_csv="/tmp/tags_all_countries.csv"
throttle=${throttle:-1}

#color output codes
YELLOW='\033[1;33m'
NC='\033[0m'



date=`date`

echo
printf "Using ${YELLOW}taginfo.geofabrik servers${NC}\n"
printf "Comparing ${YELLOW}${tag1}${NC} to ${YELLOW}${tag2}${NC} in each country\n"
echo "Start processing at $date"
echo


./taginfo_compare_tags.py --level 2 --csv $tag_count_csv

wgetreturn=$?
    if [[ $wgetreturn -ne 0 ]]; then
        echo "Failed to read from overpass server at $server/api/interpreter; check the URL"
	exit 1
    fi


csvoutput=$( cat $tag_count_csv )

if [ ! -z "$map" ]
then
  echo -e "$csvoutput" | ./plot_overPass.R --tag1 "$tag1" --tag2 "$tag2" -o "$map" -c "$color"
  printf "Saved map: ${YELLOW}${map}${NC}\n"
fi

if [ ! -z "$csv" ]
then
  echo -e "$csvoutput" > "$csv"
  printf "Saved csv: ${YELLOW}${csv}${NC}\n"
fi

date=`date`
echo
echo "Finish processing at $date"
printf 'Runtime: %02dh:%02dm:%02ds\n' $(($SECONDS/3600)) $(($SECONDS%3600/60)) $(($SECONDS%60))

