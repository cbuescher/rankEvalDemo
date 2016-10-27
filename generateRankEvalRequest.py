
from elasticsearch import Elasticsearch
import json
import sys

# Prequesites: 
#    - elasticsearch instance running at localhost:9200
#    - needed wiki articles indexed with indexBulk.sh

# Generates a rank eval request for wikipedia data (https://phabricator.wikimedia.org/P3255) that includes all queries given in the parameter list.
# For each of the queries only one request is generated that is a "match" query on the field "opening_text".
# This request includes the available ratings for each document given in discernatron_ratings.tsv.

# example:
# >python3 generateRankEvalRequest 'latin dative' 'united broadband'
# will result in this output:
# 

# {
#   "requests": [
#     {
#       "ratings": [
#         {
#           "rating": 1,
#           "_type": "page",
#           "_id": "2680742",
#           "_index": "enwiki_rank"
#         },
#         ...
#       ],
#       "request": {
#         "query": {
#           "match": {
#             "opening_text": {
#               "query": "hydrostone halifax nova scotia"
#             }
#           }
#         }
#       },
#       "id": "0"
#     },
#     {
#       "ratings": [
#         {
#           "rating": 0,
#           "_type": "page",
#           "_id": "234538",
#           "_index": "enwiki_rank"
#         },
#         ...
#       ],
#       "request": {
#         "query": {
#           "match": {
#             "opening_text": {
#               "query": "latin dative"
#             }
#           }
#         }
#       },
#       "id": "1"
#     }
#   ],
#   "metric": {
#     "reciprocal_rank": {
#       "max_acceptable_rank": 10
#     }
#   }
# }
#  



def printAllQueries() :
    f = open('discernatron_ratings.tsv', 'r')

    i = 0
    querySet = set()
    for line in f:
        parts = line.split('\t')
        querySet.add(parts[0])
        #print (parts)
        i=i+1

    print ('To create a rank eval request, add the queries you want to include as parameters. ') 
    print ('The following queries are available: \n') 

    print ("\n".join(str(e) for e in querySet))


def createRequestForQuery(queryString, requestId) :
    f = open('discernatron_ratings.tsv', 'r')

    # find all ratings related to a query
    ratingDocTitlesAndRatings = set()
    for line in f:
        parts = line.split('\t')
        if (queryString == parts[0]) :
            ratingDocTitlesAndRatings.add((parts[1], parts[2]))
    
    idsAndRatings = set()
    es = Elasticsearch()
    
    # find the corresponding doc ids is elasticsearch
    for docTitle in ratingDocTitlesAndRatings:
        query = {
                  "query": {
                    "match": {
                      "title.keyword": docTitle[0]
                    }
                  }
                }

        queryResult = es.search(body = query)
        try:
            docId = queryResult['hits']['hits'][0]['_id']
            idsAndRatings.add((docId, docTitle[1]))
        except :
            print ('failed for title ' + docTitle[0])
    
    # generate the actual request
    ratings = []
    for idAndRating in idsAndRatings : 
        ratings.append(
            {
                '_index' : 'enwiki_rank',
                '_type' : 'page',
                '_id' : str(idAndRating[0]),
                'rating': float(idAndRating[1])
            }
        )
    request = {
            'id' : requestId,
            'request': {
                "query" : {
                  "match" : {
                    "opening_text" : {
                      "query" : queryString
                    }
                  }
                }
            },
            'ratings': ratings
        }
    return request
        
def createRequestForQueries(queryStrings) : 
    requests = []
    idCounter = 0
    for queryString in queryStrings :
        print('processing query ' + queryString)
        requests.append(createRequestForQuery(queryString, str(idCounter)))
        idCounter=idCounter+1
        
    return {
                'requests': requests, 
                "metric" : {
                   "reciprocal_rank" : {
                       "max_acceptable_rank" : 10
                    }
                }
            }
        
def main(argv):
    if len(argv) == 0 :
        printAllQueries()
    else :
        request = createRequestForQueries(argv)
        print(json.dumps(request))


if __name__ == '__main__':
    main(sys.argv[1:])





