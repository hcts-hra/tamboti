xquery version "3.1";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

let $credentials := "editor:" || $config:dba-credentials[2]

let $http-headers :=
    <headers>
        <header name="Authorization" value="Basic {util:string-to-binary($credentials)}"/>
        <header name="Content-type" value="application/x-www-form-urlencoded"/>
    </headers>
let $form-fieds :=
    <httpclient:fields>
        <httpclient:field name="type" value="newspaper-article" type="string"/>
        <httpclient:field name="collection" value="/apps/tamboti/tests/resources/temp" type="string"/>
    </httpclient:fields>    
    
let $record-id := util:binary-to-string(httpclient:get(xs:anyURI("http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/api/uuid"), false(), ())/*[2])
let $api-url := xs:anyURI("http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/api/editors/hra-mods-editor/" || $record-id)
let $resources := httpclient:post-form($api-url, $form-fieds, false(), $http-headers)/*[2]/*


return $resources
