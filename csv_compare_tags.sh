#!/bin/bash

#defaults
server=${server:-"http://lz4.overpass-api.de"}
tag1=${tag1:-"waterway=riverbank"}
tag2=${tag2:-"water=river"}

#command-line arguments
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done

date=`date`

#echo "using overpass server $server/api/interpreter"
#echo "comparing $tag1 to $tag2 in each country"
#echo "Start processing at $date"
#echo

#wget -qO /tmp/all_country_ids.txt --post-file=queries/all_country_ids.op \
#  "$server/api/interpreter"

echo "iso_a2,name,$tag1,$tag2"

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
  echo "$name,$counts"
  name=
  counts=
done </tmp/all_country_ids.txt

#date=`date`
#echo
#echo "Finish processing at $date\n"
