 curl  -X GET 'http://localhost:7700/indexes/packages/documents?limit=2&offset=15000'
 
curl \
    -X POST 'http://localhost:7700/indexes/packages/search' \
    -H 'Content-Type: application/json' \
    --data-binary '{ "q": "git" }'


curl \
    -X POST 'http://localhost:7700/indexes/packages/settings/ranking-rules' \
    -H 'Content-Type: application/json' \
    --data-binary '[
        "exactness",
        "words",
        "typo",
        "proximity",
        "attribute",
        "sort",
        "release_date:asc",
        "rank:desc"
    ]'


curl \
    -X POST 'http://localhost:7700/indexes/packages/settings' \
    -H 'Content-Type: application/json' \
    --data-binary '{ "distinctAttribute": "frozen.name" }'

 

curl \
    -X GET 'http://localhost:7700/indexes/packages/settings/searchable-attributes'
curl \
    -X POST 'http://localhost:7700/indexes/packages/settings/searchable-attributes' \
    -H 'Content-Type: application/json' \
    --data-binary '[
        "*"
    ]'


curl \
    -X DELETE 'http://localhost:7700/indexes/packages/settings'
curl \
    -X GET 'http://localhost:7700/indexes/packages/settings'

 
