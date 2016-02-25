xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

let $credentials := "editor:" || $config:dba-credentials[2]

let $http-headers :=
    <headers>
        <header name="Authorization" value="Basic {util:string-to-binary($credentials)}"/>
    </headers>
    
let $api-url := xs:anyURI("http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/api/editors/hra-mods-editor/uuid-23b9dc11-ec19-4231-8323-6775688b2704")
let $resources := httpclient:get($api-url, false(), $http-headers)


return $resources
