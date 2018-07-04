#!/bin/bash

# change the following url and index names to reflect your local ES instance and source index
es_target=localhost:9200
target=enwiki_rank

# clean target index in case it already exists
index_status=`curl -o /dev/null -s -w "%{http_code}" -I $es_target/$target`

if [[ $index_status -eq 200 ]]; then 
  echo "Removing target index $es_target/$target"
  curl -s -XDELETE $es_target/$target?pretty
fi

# copy over settings and mappings from source index
echo "copy settings to $target"
cat enwiki-settings.json | curl -XPUT -H 'Content-Type: application/json'  $es_target/$target?pretty -d @-

echo "copy mapping to $target"
cat enwiki-mapping.json | curl -XPUT -H 'Content-Type: application/json' $es_target/$target/_mapping/page?pretty -d @-

# finally write everything in bulk
echo "bulk indexing"

# chop down bulk file, might be too large otherwise
for file in bulkdata/bulkpart_*; do
  echo -n "indexing ${file}"
  result=$(curl -s -XPOST -H 'Content-Type: application/json' $es_target/$target/_bulk?pretty --data-binary @$file)
  # echo $result > ${file}_bulklog.txt
  took=$(echo $result |    grep took | cut -d':' -f 2 | cut -d',' -f 1)
  printf ', took %7s ms.\n' $took
  [ "x$took" = "x" ] 
done
