#!/bin/bash

# change the following url and index names to reflect your local ES instance and source index
#export es=192.168.2.201:9200
export es=192.168.2.110:9200
export es_target=localhost:9200
export index=enwiki
export target=enwiki_rank

# clean target index in case it already exists
echo "Removing old target index if it exists. Ignore errors if index didn't exist before"
curl -s -XDELETE $es_target/$target?pretty

# copy over settings and mappings from source index
echo "copying source settings to target"
curl -s -XGET $es/$index/_settings |
  jq --arg ind $index '{
    analysis: .[$ind].settings.index.analysis,
    number_of_shards: 1,
    number_of_replicas: 0
  }' |
  curl -XPUT $es_target/$target?pretty -d @-  

echo "copying source mapping to target"
# TODO remove manual correction step
curl -s -XGET $es/$index/_mapping |
  jq --arg ind $index .[$ind].mappings.page > mapping.txt
cat corrected_mapping.txt | curl -XPUT $es_target/$target/_mapping/page?pretty -d @-


# get all articles that are rated in discernatron_ratings.tsv, lookup by title
echo "retrieving all rated files from source index by title"
cat discernatron_ratings.tsv|awk -F'\t' '{print $2}' > titles.txt
[ -f bulk_index.txt ] && rm bulk_index.txt

while read title; 
do
  result=$(echo "{}" | jq --arg titel "$title" '{ query: { match: { "title.keyword": $titel } } }' | curl -s -XGET $es/$index/page/_search?pretty -d @-)
  id=$(echo $result | jq -r .hits.hits[0]._id)
  source=$(echo $result | jq -c .hits.hits[0]._source)
  if [ $id != null ]; then
     echo '{"index" : { "_index" : "'$target'", "_type" : "page", "_id" : "'$id'" } }' >> bulk_index.txt
     echo $source >> bulk_index.txt
  else
     echo "title [$title] not found"
  fi
done <titles.txt

# also add some article that are potentially not rated by using
# the query string against the all field and copy top 10 hits
echo "running all queries on _all field and get top 10"
cat discernatron_ratings.tsv|awk -F'\t' '{print $1}' | sort | uniq > queries.txt 

while read query;
do
  result=$(echo "{}" | 
    jq --arg query "$query" '{ query: { match: { "all": $query } } }' |
    curl -s -XGET $es/$index/page/_search?pretty -d @-)
  hits=$(echo $result | jq ' .hits.hits | length')
  if [ $hits != 0 ]; then
    echo "Hits for [$query]: $hits"
    for (( i=0; i <= $((hits-1)); ++i ))
    do
      #echo "$i"
      id=$(echo $result | jq --arg i $i -r ' .hits.hits[$i|tonumber]._id')
      source=$(echo $result | jq --arg i $i -c ' .hits.hits[$i|tonumber]._source')
      echo '{"index" : { "_index" : "'$target'", "_type" : "page", "_id" : "'$id'" } }' >> bulk_index.txt
      echo $source >> bulk_index.txt
    done
  else
    echo "Nothing found for [$query]"
  fi
done <queries.txt

# finally write everything in bulk
echo "bulk indexing"

# chop down bulk file, might be too large otherwise
split -a 3 -l 500 bulk_index.txt bulkpart_
for file in bulkpart_*; do
  echo -n "${file}:  "
  took=$(curl -s -XPOST $es_target/$target/_bulk?pretty --data-binary @$file |
    grep took | cut -d':' -f 2 | cut -d',' -f 1)
  printf '%7s\n' $took
  [ "x$took" = "x" ] || rm $file
done
