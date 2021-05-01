#!/bin/bash

wget -qO /tmp/all_country_ids.txt --post-file=queries/all_country_ids.op \
  "$1/api/interpreter"

echo "name,name(local),riverbank,river"

while read p; do
  base_area=3600000000
  area_id=`expr $base_area + $p`
  query=`sed "s/#AREA/$area_id/g" queries/count_riverbank.op`
  namequery=`sed "s/#ID/$p/g" queries/id_to_name.op`
  counts=$(wget -qO- --post-data="$query" "$1/api/interpreter")
  name=$(wget -qO- --post-data="$namequery" "$1/api/interpreter")
  echo "$name,$counts"
done </tmp/all_country_ids.txt
