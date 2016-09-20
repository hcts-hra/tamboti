xquery version "3.1";

(:
 : Example: Query mongodb
 : 
 : User must be either DBA or in group mongodb
 :)

import module namespace mongodb = "http://expath.org/ns/mongo" 
                at "java:org.exist.mongodb.xquery.MongodbModule";

let $mongoUrl   := "mongodb://localhost"
let $database   := "tamboti-test"
let $collection := "manifests"
let $query      := '{"@id": "http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/api/manifest/e3b1489e-4149-42c5-81d0-349d243f6b2f"}'

(: connect to mongodb :)
let $mongodbClientId := mongodb:connect($mongoUrl)
let $json := mongodb:find($mongodbClientId, $database, $collection, $query)
(:let $json-map := parse-json($json):)
let $header := response:set-header("Content-Type", "application/json")
return
    $json
