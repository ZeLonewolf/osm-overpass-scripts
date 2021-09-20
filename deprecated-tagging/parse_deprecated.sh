#!/bin/bash
json=$(curl -s https://raw.githubusercontent.com/openstreetmap/id-tagging-schema/main/data/deprecated.json)

IFS=$'\n'
tags=($(echo "$json" \
        | grep "[old|replace]" \
        | sed 's/": "/=/g; 
               s/", "/+/g; 
               s/[{"|"}]//g;
               s/.*: //g;
               s/\$1/*/g' \
        | tr '\n' '\r' \
        | sed 's/,\r/|/g' \
        | tr '\r' '\n'))


wikiTabTop='{| class="wikitable sortable"'
wikiHeader='! Old tag !! New tag'
wikiNewRow='|-'
wikiTabBottom='|}'


echo "${wikiTabTop}"
echo "${wikiNewRow}"
echo "${wikiHeader}"


for tag in ${tags[@]}; do
    old=($(echo "$tag" | cut -f 1 -d "|" | sed 's/+/}}+{{Tag|/g; s/=/|/g'))
    new=$(echo "$tag" | cut -f 2 -d "|" | sed 's/+/}}+{{Tag|/g; s/=/|/g')

    echo "${wikiNewRow}"
    echo "| {{Tag|${old}}} || {{Tag|${new}}}"
done

echo "${wikiTabBottom}"






# curl -s 'https://raw.githubusercontent.com/openstreetmap/id-tagging-schema/main/data/deprecated.json' \
#     | python3 -c "import sys, json; print(json.load(sys.stdin)[1]['old']['aeroway'])"







