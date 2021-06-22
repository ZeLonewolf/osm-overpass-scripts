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
tag1=${tag1:-"waterway=riverbank"}


#color output codes
YELLOW='\033[1;33m'
NC='\033[0m'



date=`date`

echo
printf "Calculating usage history of ${YELLOW}${tag1}${NC}"
if [ ! -z "$tag2" ]; then printf " vs. ${YELLOW}${tag2}${NC}"; fi
printf " objects\n"
echo "Start processing at $date"
echo


# Get data from taginfo
echo "@date,@nodes,@ways,@relations" > /tmp/tag1_counts.tmp

curl -s "https://taginfo.openstreetmap.org/api/4/tag/chronology?key=${tag1%%=*}&value=${tag1##*=}" \
    | tr '{' '\n' \
    | grep "date" \
    | sed 's/[]|"|}]//g; s/:/,/g' \
    | cut -f 2,4,6,8 -d ',' >> /tmp/tag1_counts.tmp


if [ ! -z "$tag2" ]; then
    echo "@date,@nodes,@ways,@relations" > /tmp/tag2_counts.tmp

    curl -s "https://taginfo.openstreetmap.org/api/4/tag/chronology?key=${tag2%%=*}&value=${tag2##*=}" \
        | tr '{' '\n' \
        | grep "date" \
        | sed 's/[]|"|}]//g; s/:/,/g' \
        | cut -f 2,4,6,8 -d ',' >> /tmp/tag2_counts.tmp
fi


# Plot data
if [ ! -z "$plot" ]; then
    ${0%/*}/plot_tagHistory.R -i /tmp/tag1_counts.tmp \
                              $(  if [ ! -z "$tag2" ]; then echo "-j /tmp/tag2_counts.tmp"; fi) \
                              --tag1 "$tag1" \
                              $(  if [ ! -z "$tag2" ]; then echo "--tag2 $tag2"; fi ) \
                              -o "$plot" \
                              --binwidth "$binwidth"
    
    printf "Saved plot: ${YELLOW}${plot}${NC}\n"
fi

# Save to csv
if [ ! -z "$csv" ]; then
    mv /tmp/tag1_counts.tmp tag1_counts.csv
    printf "Saved ${tag1} csv: ${YELLOW}tag1_counts.csv${NC}\n"

    if [ ! -z "$tag2" ]; then
        mv /tmp/tag2_counts.tmp tag2_counts.csv
        printf "Saved ${tag2} csv: ${YELLOW}tag2_counts.csv${NC}\n"
    fi

fi