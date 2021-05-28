#!/bin/bash

#defaults
#server=${server:-"http://lz4.overpass-api.de"}
server=${server:-"https://overpass.kumi.systems"}
tag=${tag:-"waterway=riverbank"}
binwidth=${binwidth:-1}
countries=${countries:-"no"}
throttle=5
bbox=
rate=$(curl -s "${server}/api/status" | grep "Rate limit" | cut -f 3 -d ' ')

echo $0
echo ${0%/*}

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
    printf "There are ${YELLOW}${tcount}${NC} objects in total\n"


    # based on tag count, decide how small planet fragments to make
    if [ "$tcount" -le 300000 ]; then       # 0.3 mil
        split=360   # whole planet
    elif [ "$tcount" -le 1000000 ]; then    # 1 mil
        split=45    #15
    elif [ "$tcount" -le 10000000 ]; then   # 10 mil
        split=30    #10
    else
        split=5
    fi
                    #split=90    # 8 framents
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


echo -e "@lat,@lon\n" > /tmp/${csv%.*}.tmp



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
    if [ $(echo "$out" | grep -c "remark") -eq 1 ] || [ $(echo "$out" | wc -l) -eq 1 ]; then
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

    # Parse xml to csv (we can't do out:csv because of missing error messages in csv queries)
    out=$(echo "$out" | grep "lon"| cut -f 2 -d "a" | cut -f 2,4 -d '"' | tr '"' ',')

    if [ ! $(echo -n "$out" | wc -l) -eq 0 ]; then
        echo -e "${out}\n" >> /tmp/${csv%.*}.tmp
    fi

    echo -n "$out" | wc -l
    sleep "$throttle"
    shift
done


printf 'Query time: %02dh:%02dm:%02ds\n' $(($SECONDS/3600)) $(($SECONDS%3600/60)) $(($SECONDS%60))

if [ ! -z "$map" ]; then
    ./plot_tagDensity.R -i /tmp/${csv%.*}.tmp --tag "$tag" -o "$map" --binwidth "$binwidth" --bbox "$bbox" --countries "$countries"
    printf "Saved map: ${YELLOW}${map}${NC}\n"
fi

if [ ! -z "$csv" ]; then
    mv /tmp/${csv%.*}.tmp "$csv"
    printf "Saved csv: ${YELLOW}${csv}${NC}\n"
fi



date=`date`
echo
echo "Finished processing at $date"
printf 'Runtime: %02dh:%02dm:%02ds\n' $(($SECONDS/3600)) $(($SECONDS%3600/60)) $(($SECONDS%60))

