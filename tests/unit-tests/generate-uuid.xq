xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

let $credentials := "editor:" || $config:dba-credentials[2]

let $http-headers :=
    <headers>
        <header name="Authorization" value="Basic {util:string-to-binary($credentials)}"/>
        <header name="Content-Type" value="text/plain"/>
    </headers>
    
let $api-url := xs:anyURI("http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/api/uuid")
let $resources := httpclient:get($api-url, false(), $http-headers)


return util:binary-to-string($resources/*[2])
