#!/bin/bash

#defaults
server=${server:-"http://lz4.overpass-api.de"}
tag1=${tag1:-"waterway=riverbank"}
tag2=${tag2:-"water=river"}
color=${color:-"GR"}
tmpcsv="/tmp/all_country_ids.csv"
throttle=5

#color output codes
YELLOW='\033[1;33m'
NC='\033[0m'

#command-line arguments
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done

date=`date`

echo
printf "Using overpass server ${YELLOW}${server}/api/interpreter${NC}\n"
printf "Comparing ${YELLOW}${tag1}${NC} to ${YELLOW}${tag2}${NC} in each country\n"
echo "Start processing at $date"
echo

wget -qO "$tmpcsv" --post-file=queries/all_country_ids.op \
  "$server/api/interpreter"

wgetreturn=$?
    if [[ $wgetreturn -ne 0 ]]; then
        echo "Failed to read from overpass server at $server/api/interpreter; check the URL"
	exit 1
    fi

csvoutput="iso_a2,name,$tag1,$tag2"
csvlines=`wc -l < "$tmpcsv"`

echo "processing $csvlines countries"
echo "@[iso,name]: $tag1, $tag2"
echo "------------------------------"

while read p; do
  base_area=3600000000
  area_id=`expr $base_area + $p`
  query=`sed "s/#AREA/$area_id/g; s/#TAG1/$tag1/g; s/#TAG2/$tag2/g" queries/count_tags.op`
  namequery=`sed "s/#ID/$p/g" queries/id_to_name.op`
  while [ -z "$counts" ]; do
    counts=$(wget -qO- --post-data="$query" "$server/api/interpreter")
    sleep "$throttle"
  done
  while [ -z "$name" ]; do
    name=$(wget -qO- --post-data="$namequery" "$server/api/interpreter")
    sleep "$throttle"
  done
  csvoutput="${csvoutput}\n${name},${counts}"
  echo "[$name]: $counts"
  name=
  counts=

  #echo -e "$csvoutput" > out.csv

done <"$tmpcsv"

csvoutput="${csvoutput}\n"

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

