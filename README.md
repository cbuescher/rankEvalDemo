# Demo for using Elasticsearch Ranking Evaluation API

The Ranking Evaluation API allows to evaluate the quality of ranked search results over a set of typical search queries. Given this set of queries and a list or manually rated documents, the _rank_eval endpoint calculates and returns
typical information retrieval metrics like mean reciprocal rank, precision or discounted cumulative gain.

For further on the API are available in the [documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-rank-eval.html)

This project contains example documents from the english Wikipedia corpus to demonstrate the API.

## Setup

In order to run the demo, you currently need at least Elasticsearch 6.2 installed. In addition to that you need to install the `analysis-icu` plugin to be able to use the wikipedia mapping:

```
./bin/elasticsearch-plugin install analysis-icu
```

Next, run the `indexBulk.sh` script contained in this project. The script assumes you are running Elasticsearch locally on port 9200 and installs the demo data, including settings and mappings, to an index called `enwiki_rank`. 

After that you should be ready to run the examples from `demo_rank_eval.txt` in Kibana.