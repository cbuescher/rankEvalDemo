#!/bin/bash

export es=192.168.2.201:9200
export index=enwiki
export target=enwiki_rank

curl -s -XDELETE $es/$target

echo "copying source settings to target"
curl -s -XGET $es/$index/_settings |
  jq --arg ind $index '{
    analysis: .[$ind].settings.index.analysis,
    number_of_shards: 1,
    number_of_replicas: 0
  }' |
  curl -XPUT $es/$target?pretty -d @-  

echo "copying source mapping to target"
curl -s -XGET $es/$index/_mapping |
  jq --arg ind $index .[$ind].mappings.page |
  curl -XPUT $es/$target/_mapping/page?pretty -d @-

echo "retrieving all rated files from source index by title"
cat discernatron_ratings.tsv|awk -F'\t' '{print $2}' > titles.txt
[ -f bulk_index.txt ] && rm bulk_index.txt

while read title; 
do
  result=$(echo "{}" | jq --arg titel "$title" '{ query: { match: {
"title.keyword": $titel } } }' |
  curl -s -XGET $es/$index/page/_search?pretty -d @-)
  id=$(echo $result | jq -r .hits.hits[0]._id)
  source=$(echo $result | jq -c .hits.hits[0]._source)
  if [ $id != null ]; then
     echo '{"index" : { "_index" : "'$target'", "_type" : "page", "_id" : "'$id'" } }' >> bulk_index.txt
     echo $source >> bulk_index.txt
  else
     echo "title [$title] not found"
  fi
  #echo $source | curl -s -XPUT $es/$target/page/$id?pretty -d @-
done <titles.txt

echo "bulk indexing"
curl -s -XPOST $es/$target/_bulk --data-binary "@bulk_index.txt";

echo "running all queries on all field and get top 10"
cat cat discernatron_ratings.tsv|awk -F'\t' '{print $1}' | sort | uniq > queries.txt 
