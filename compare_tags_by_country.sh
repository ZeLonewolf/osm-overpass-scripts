#!/bin/bash

#defaults
server=${server:-"http://lz4.overpass-api.de"}
tag1=${tag1:-"waterway=riverbank"}
tag2=${tag2:-"water=river"}
plot=${plot:-"output.png"}
tmpcsv="/tmp/all_country_ids.csv"

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
printf "using overpass server ${YELLOW}${server}/api/interpreter${NC}\n"
printf "comparing ${YELLOW}${tag1}${NC} to ${YELLOW}${tag2}${NC} in each country\n"
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

while read p; do
  base_area=3600000000
  area_id=`expr $base_area + $p`
  query=`sed "s/#AREA/$area_id/g; s/#TAG1/$tag1/g; s/#TAG2/$tag2/g" queries/count_tags.op`
  namequery=`sed "s/#ID/$p/g" queries/id_to_name.op`
  while [ -z "$counts" ]; do
    counts=$(wget -qO- --post-data="$query" "$server/api/interpreter")
    sleep 5
  done
  while [ -z "$name" ]; do
    name=$(wget -qO- --post-data="$namequery" "$server/api/interpreter")
    sleep 5
  done
  csvoutput="${csvoutput}\n${name},${counts}"
  echo "[$name]: $counts"
  name=
  counts=

  echo -e "$csvoutput" > out.csv

done <"$tmpcsv"

csvoutput="${csvoutput}\n"

if [ -z "$chart" ]
then
  echo -e "$csvoutput" | ./plot_overPass.R --tag1 "$tag1" --tag2 "$tag2" -o "$chart"
  printf "Saved map: ${YELLOW}${chart}${NC}"
fi

if [ -z "$csv" ]
then
  echo -e "$csvoutput" > "$csv"
  printf "Saved csv: ${YELLOW}${csv}${NC}"
fi

date=`date`
echo
echo "Finish processing at $date\n"
