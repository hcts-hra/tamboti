xquery version "3.1";

(:
 : Example: Query mongodb
 : 
 : User must be either DBA or in group mongodb
 :)

import module namespace mongodb = "http://expath.org/ns/mongo" 
                at "java:org.exist.mongodb.xquery.MongodbModule";

let $id := request:get-parameter("id", "http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/api/manifest/5330871d-8288-485c-b807-57f5186f59d3")
let $mongoUrl   := "mongodb://localhost"
let $database   := "tamboti-test"
let $collection := "manifests"
(:let $query      := '{"@id":"http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/api/manifest/c91ee663-b4bf-4b41-9b64-d551a4de0f35"}':)
let $query      := '{"@id": "' || $id || '"}'
    let $log := util:log("INFO", $query)

(: connect to mongodb :)
let $mongodbClientId := mongodb:connect($mongoUrl)
let $json := mongodb:find($mongodbClientId, $database, $collection, $query)
(:let $json-map := parse-json($json):)
let $header := response:set-header("access-control-allow-origin", "*")
let $header := response:set-header("Content-Type", "application/json")
return
    $json
