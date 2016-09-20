xquery version "3.1";

import module namespace functx="http://www.functx.com";
import module namespace security = "http://exist-db.org/mods/security" at "/apps/tamboti/modules/search/security.xqm";
import module namespace hra-anno-framework = "http://hra.uni-heidelberg.de/ns/hra-anno-framework" at "/db/apps/tamboti/frameworks/hra-annotations/hra-annotations.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace c="http://hra.uni-heidelberg.de/ns/tamboti/annotations/config";

let $url := "http://localhost:8080/exist/apps/tamboti/api/annotationsFor/uuid-5dffa05e-50fa-4a0e-bcdf-cba7e7a6668c"

return 
    let $json := httpclient:get($url, false(), ())//httpclient:body
    (:let $head := response:set-header("Content-Type", "application/json"):)
    (:let $data := hra-anno-framework:get-annotation-nodes($json):)
    (:let $test := hra-anno-framework:eval-as-target($data, "canvas-editor"):)
    return
        $json
(:    util:log("INFO", in-scope-prefixes(util:eval(""))):)
(:    $data?('target-definition'):)
(:    $test:)
(:    $test?('target-short'):)
(:    hra-rdf-framework:process-displayHint($target-xml-node, $var-map as map()) {:)



(:util:eval(xs:anyURI("/db/apps/tamboti/frameworks/hra-annotations/annotations.xq"), false(), ((xs:QName("action"), "as-body-or-target"), (xs:QName("iri"), "http://localhost:8080/exist/apps/tamboti/api/resource/uuid-d868196a-29dc-4be1-a956-ac0f950a4e05"))):)