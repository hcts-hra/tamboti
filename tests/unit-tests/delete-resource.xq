xquery version "3.1";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

let $cluster-publications-collection-name := "Cluster Publications"    
let $cluster-publications-db-path := xmldb:encode-uri($config:mods-commons || "/" || $cluster-publications-collection-name)
let $credentials := "editor:editor"

let $http-headers :=
    <headers>
        <header name="Authorization" value="Basic {util:string-to-binary($credentials)}"/>
        <header name="X-resource-path" value="{$cluster-publications-db-path}/headers.xml"/>
    </headers>
    
let $api-url := xs:anyURI("http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/api/resources")
let $resources := httpclient:delete($api-url, false(), $http-headers)


return $resources
