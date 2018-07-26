# Demo for using Elasticsearch Ranking Evaluation API

The Ranking Evaluation API allows to evaluate the quality of ranked search results over a set of typical search queries. Given this set of queries and a list or manually rated documents, the `_rank_eval` endpoint calculates and returns typical information retrieval metrics like mean reciprocal rank, precision or discounted cumulative gain.

For further on the API are available in the [documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-rank-eval.html)

## Setup

In order to run the demo, you need at least Elasticsearch 6.2 installed.
Next, run the `setup.sh` script contained in this project. The script assumes you are running Elasticsearch locally on port 9200 and installs the demo data, including settings and mappings, to an index called `enwiki_rank`. 

After that you should be ready to run the examples from `demo_rank_eval.txt` in the Kibana Console.

## Data

This demo is based on a small subset of documents from the [English Wikipedia dump](https://dumps.wikimedia.org)
which is also available in an [Elasticsearch bulk format](https://dumps.wikimedia.org/other/cirrussearch/).
The relevance judgement data used for the evaluation is based on data collected in the Wikimedia labs [Discernatron Project](https://discernatron.wmflabs.org/login)
and is available for registered Wikimedia users for [download](https://discernatron.wmflabs.org/scores/all) separately. 
