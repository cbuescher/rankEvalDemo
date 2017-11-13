#!/bin/bash

# change the following url and index names to reflect your local ES instance and source index
export es_target=localhost:9200
export target=enwiki_rank

# clean target index in case it already exists
echo "Removing old target index if it exists. Ignore errors if index didn't
exist before"
curl -s -XDELETE $es_target/$target?pretty

# copy over settings and mappings from source index
echo "putting settings to target"
cat orig_settings.txt | curl -XPUT -H 'Content-Type: application/json'  $es_target/$target?pretty -d @-

echo "copying source mapping to target"
cat corrected_mapping.txt | curl -XPUT -H 'Content-Type: application/json' $es_target/$target/_mapping/page?pretty -d @-

# finally write everything in bulk
echo "bulk indexing"

# chop down bulk file, might be too large otherwise
for file in parts/bulkpart_*; do
  echo -n "${file}:  "
  took=$(curl -s -XPOST -H 'Content-Type: application/json' $es_target/$target/_bulk?pretty --data-binary @$file |
    grep took | cut -d':' -f 2 | cut -d',' -f 1)
  printf '%7s\n' $took
  [ "x$took" = "x" ] 
done
