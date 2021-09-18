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
#server=${server:-"http://lz4.overpass-api.de"}
server=${server:-"https://overpass.kumi.systems"}
tag=${tag:-"waterway=riverbank"}
binwidth=${binwidth:-1}
countries=${countries:-"no"}
throttle=${throttle:-1}
bbox=${bbox:-}
location=${location:-}
rate=$(curl -s "${server}/api/status" | grep "Rate limit" | cut -f 3 -d ' ')


# Set bbox according to the location preset
case $location in
    Europe) bbox="34,-13,65,48" ;;
    USA) bbox="24,-126,51,-65" ;;
    Africa) bbox="-36,-21,39,55" ;;
    Asia) bbox="-11,25,77,180" ;;
    NAmerica) bbox="9,-168,73,-51" ;;
    SAmerica) bbox="-56,-90,17,-31" ;;
    Australia) bbox="-47,106,8,180" ;;
esac

#color output codes
YELLOW='\033[1;33m'
NC='\033[0m'



date=`date`

echo
printf "Using overpass server ${YELLOW}${server}/api/interpreter${NC}\n"
printf "Calculating density of ${YELLOW}${tag}${NC} objects\n"
echo "Start processing at $date"
echo



if [ -z "$bbox" ]; then
    # use taginfo API to obtain total count of objects
    if [[ $tag =~ "=" ]]; then
        taginfo="https://taginfo.openstreetmap.org/api/4/tag/stats?key=${tag%%=*}&value=${tag##*=}"
    else
        taginfo="https://taginfo.openstreetmap.org/api/4/key/stats?key=${tag}"
    fi

    tcount=$(curl -s "$taginfo" \
                | tr -d '{}[]"' \
                | cut -f 5 -d "," \
                | cut -f 2 -d ":")

    tcount=${tcount:-0}

    printf "There are ${YELLOW}${tcount}${NC} objects in total\n"


    # based on tag count, decide how small planet fragments to make
    if [ "$tcount" -le 500000 ]; then        # 0.5 mil
        split=360   # whole planet
    elif [ "$tcount" -le 10000000 ]; then    # 10 mil
        split=60    # 18
    elif [ "$tcount" -le 100000000 ]; then   # 100 mil
        split=30    # 72
    else
        split=5
    fi
                    #split=90    # 8 framents
                    #split=60    # 18 fragments
                    #split=45    # 32 fragments
                    #split=30    # 72 fragments
                    #split=20    # 162 fragments
                    #split=15    # 288 fragments
                    #split=10    # 648 fragments
                    #split=5     # 2592 fragments
                    #split=2     # 16200 fragments
                    #split=1     # 64800 fragments

    # split planet into bboxes
    q_bbox=($(awk -v s="$split" -v OFS="," 'BEGIN { for (i=-180; i<180; i+=s){
                                                        for (j=-90; j<90; j+=s){
                                                            print "[bbox:"j, i, j+s, i+s"]"
                                                        }
                                                   }
                                                 }'))

    printf "Processing whole planet in ${YELLOW}${#q_bbox[@]} bbox${NC} areas\n"
else
    q_bbox="[bbox:${bbox}]"
    split=0
    printf "Processing ${YELLOW}${q_bbox} bbox${NC} area\n"
fi


echo "@lat,@lon" > /tmp/tag_csv.tmp



set ${q_bbox[@]}        # seting bboxes as parameters to allow queue updating, which is not possible with for-loop
while [ "$#" -gt 0 ]; do
    b="$1"
    if [ "$split" -eq 360 ]; then b= ; split=0 ; fi     # When split == 360 remove bbox from query for the whole planet
    
    printf "${YELLOW}${b}${NC} "


    # Check with server if query slot is available now
    full=
    while [ $(curl -s "${server}/api/status" | grep -c "now") -eq 0 ] && [ "$rate" -gt 0 ]; do
        if [ -z "$full" ]; then
            printf "Waiting for next available slot... "
            full="yes"
        fi
        sleep 1
    done
    if [ "$full" = "yes" ]; then printf "Slot found "; fi


    # Run query
    query=`sed "s/#TAG/$tag/g; s/#BBOX/$b/g" ${0%/*}/queries/find_centers.op`
    out="$(curl -s -m 9000 -d "$query" -X POST "$server/api/interpreter")"

    
    # Check if query failed
    if [ ! $(echo -n "$out" | grep "^,,[0-9]" | wc -l ) -eq 1 ]; then
        # if query failed split square into 4 smaller squares and add to the queue
        printf "${YELLOW}Query failed.${NC} Splitting into smaller areas...\n"
        b_num=$(echo "$b" | cut -f 2 -d ':' | tr -d ']')
        new_bbox=$(awk -v bbox="$b_num" -v OFS="," 'BEGIN{ if (bbox == "") bbox = "-90,-180,90,180";
                                                          split(bbox, coord, ",")
                                                          shift = (coord[3] - coord[1]) / 2
                                                          shift2 = (coord[4] - coord[2]) / 2
                                                          for (i=coord[2]; i<coord[4]; i+=shift2){
                                                            for (j=coord[1]; j<coord[3]; j+=shift){
                                                                print "[bbox:"j, i, j+shift, i+shift2"]"
                                                            }
                                                          }}')
        shift
        set ${new_bbox[@]} "$@"
        continue
    fi


    # Parse output
    out=$(echo "$out" | sed '$d' | cut -f 1,2 -d ',')

    ocount=$(echo -n "$out" | wc -l)
    echo "$ocount"

    if [ ! "$ocount" -eq 0 ]; then
        echo "$out" >> /tmp/tag_csv.tmp
    fi


    shift
    sleep "$throttle"
done


printf 'Query time: %02dh:%02dm:%02ds\n' $(($SECONDS/3600)) $(($SECONDS%3600/60)) $(($SECONDS%60))

if [ ! -z "$map" ]; then
    ${0%/*}/plot_tagDensity.R -i /tmp/tag_csv.tmp --tag "$tag" -o "$map" --binwidth "$binwidth" --bbox="$bbox" --countries "$countries"
    printf "Saved map: ${YELLOW}${map}${NC}\n"
fi

if [ ! -z "$csv" ]; then
    mv /tmp/tag_csv.tmp "$csv"
    printf "Saved csv: ${YELLOW}${csv}${NC}\n"
fi



date=`date`
echo
echo "Finished processing at $date"
printf 'Runtime: %02dh:%02dm:%02ds\n' $(($SECONDS/3600)) $(($SECONDS%3600/60)) $(($SECONDS%60))

