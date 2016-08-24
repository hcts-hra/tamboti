xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace http="http://expath.org/ns/http-client";

let $credentials := "editor:" || $config:dba-credentials[2]

let $http-headers :=
    <headers>
        <header name="Authorization" value="Basic {util:string-to-binary($credentials)}"/>
        <header name="Content-type" value="multipart/form-data"/>
    </headers>
let $form-fieds :=
    <httpclient:fields>
        <httpclient:field name="type" value="newspaper-article" type="string"/>
        <httpclient:field name="type" value="newspaper-article" type="string"/>
    </httpclient:fields>
    
let $api-url := xs:anyURI("http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/api/editors/hra-mods-editor/uuid-23b9dc11-ec19-4231-8323-6775688b2704")
let $resources := httpclient:post-form($api-url, $form-fieds, false(), $http-headers)/*[2]/*

return $resources
