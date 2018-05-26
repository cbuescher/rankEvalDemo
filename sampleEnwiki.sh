#!/bin/bash

# change the following url and index names to reflect your local ES instance for the source index
export es=localhost:9200
export index=enwiki

# get all articles that are rated in discernatron_ratings.tsv, lookup by title
echo "retrieving all rated files from source index by title"
cat discernatron_ratings.tsv|awk -F'\t' '{print $2}' > titles.txt
[ -f bulk_index.txt ] && rm bulk_index.txt

while read title; 
do
  result=$(echo "{}" | jq --arg titel "$title" '{ query: { bool: { should: [ {
match: { "title.keyword": $titel } }, { match: { "redirect.title.keyword":
$titel } } ] } } }' | curl -s -XGET -H'Content-Type: application/json' $es/$index/page/_search?pretty -d @-
  )
  id=$(echo $result | jq -r .hits.hits[0]._id)
  source=$(echo $result | jq -c .hits.hits[0]._source)
  if [ $id != null ]; then
     echo '{"index" : { "_type" : "page", "_id" : "'$id'" } }' >> bulk_index.txt
     echo $source >> bulk_index.txt
  else
     echo "title [$title] not found"
  fi
done <titles.txt

# also add some article that are potentially not rated by using
# the query string against the all field and copy top 20 hits
echo "running all queries on _all field and get top 20"
cat discernatron_ratings.tsv|awk -F'\t' '{print $1}' | sort | uniq > queries.txt 

while read query;
do
  result=$(echo "{}" | 
    jq --arg query "$query" '{ query: { match: { "all": $query } } , "size" : 20 }' |
    curl -s -XGET  -H'Content-Type: application/json' $es/$index/page/_search?pretty -d @-)
  #echo $result
  hits=$(echo $result | jq ' .hits.hits | length')
  if [ $hits != 0 ]; then
    echo "Hits for [$query]: $hits"
    for (( i=0; i <= $((hits-1)); ++i ))
    do
      id=$(echo $result | jq --arg i $i -r ' .hits.hits[$i|tonumber]._id')
      source=$(echo $result | jq --arg i $i -c ' .hits.hits[$i|tonumber]._source')
      echo '{"index" : { "_type" : "page", "_id" : "'$id'" } }' >> bulk_index.txt
      echo $source >> bulk_index.txt
    done
  else
    echo "Nothing found for [$query]"
  fi
done < queries.txt

# split the large bulk_index.txt into parts 
split -a 3 -l 500 bulk_index.txt bulkpart_
mv bulkpart_* bulkdata 
