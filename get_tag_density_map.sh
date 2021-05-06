#!/bin/bash

#defaults
server=${server:-"http://lz4.overpass-api.de"}
tag=${tag:-"waterway=riverbank"}
binwidth=${binwidth:-1}
countries=${countries:-"no"}
throttle=5
bbox=

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
printf "Calculating density of ${YELLOW}${tag}${NC} objects\n"
echo "Start processing at $date"
echo

csvoutput="@lat,@lon"

## Alternative code to query planet in 32 bbox queries
# if [ -z "$bbox" ]; then
#     q_bbox=$(awk -v OFS="," 'BEGIN { for (i=-180; i<180; i+=45){
#                                       for (j=-90; j<90; j+=45){
#                                          print j, i, j+45, i+45
#                                       }
#                                    }
#                                  }')
# else
#     q_bbox=$bbox
# fi
#
# echo "processing whole planet in 32 bbox areas"
# for b in $q_bbox; do
#     b="[bbox:$b]"
#     echo "$b"
#     query=`sed "g; s/#TAG/$tag/g; s/#BBOX/$b/g" queries/find_centers.op`
#     csvoutput="${csvoutput}\n$(wget -qO- --post-data="$query" "$server/api/interpreter")"
#     sleep "$throttle"
# done

q_bbox=${bbox:+"[bbox:$bbox]"}
query=`sed "s/#TAG/$tag/g; s/#BBOX/$q_bbox/g" queries/find_centers.op`

csvoutput="${csvoutput}\n$(wget -qO- --post-data="$query" "$server/api/interpreter")"
csvoutput="${csvoutput}\n"

printf 'Query time: %02dh:%02dm:%02ds\n' $(($SECONDS/3600)) $(($SECONDS%3600/60)) $(($SECONDS%60))

if [ ! -z "$csv" ]; then
  echo -e "$csvoutput" > "$csv"
  printf "Saved csv: ${YELLOW}${csv}${NC}\n"
fi

if [ ! -z "$map" ]; then
  echo -e "$csvoutput" | ./plot_tagDensity.R --tag "$tag" -o "$map" --binwidth "$binwidth" --bbox "$bbox" --countries "$countries"
  printf "Saved map: ${YELLOW}${map}${NC}\n"
fi


date=`date`
echo
echo "Finish processing at $date"
printf 'Runtime: %02dh:%02dm:%02ds\n' $(($SECONDS/3600)) $(($SECONDS%3600/60)) $(($SECONDS%60))

