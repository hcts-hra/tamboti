xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";

import module namespace functx = "http://www.functx.com";

(:import module namespace iiif-functions = "http://hra.uni-heidelberg.de/ns/iiif-functions" at "/apps/tamboti/modules/display/iiif-functions.xqm";:)
import module namespace hra-iiif="http://hra.uni-heidelberg.de/ns/hra-iiif" at "/apps/tamboti/frameworks/hra-iiif/hra-iiif.xqm";

declare variable $local:json-serialize-parameters :=
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;



let $collection-name := xs:anyURI("/data/users/editor/Couleurkarten/Einzeln")
(:let $collection-name := xs:anyURI("/data/commons/Naddara"):)
(:let $collection-name := xs:anyURI("/data/commons/Naddara/documents/1888_Chesnel_Comic_Attawadod-inlay"):)
(:let $collection-name := xs:anyURI("/data/commons/Naddara/Journals/1900/1_Le-Journal-d-Abou-Naddara_issues-001-005"):)
(:let $collection-name := xmldb:encode-uri("/data/users/matthias.guth@ad.uni-heidelberg.de/GrabungKMHKastellweg/Grabungstagebuch"):)

(:let $canvases-json-map := hra-iiif:collection-canvases($collection-name):)


let $header := response:set-header("Content-Type", "application/json")
let $header := response:set-header("Access-Control-Allow-Origin", "*")
let $log := util:log("INFO", session:get-attribute-names())

(:let $httpheader := response:set-header("Disposition-type", 'inline; filename="canvas.json"'):)
(:let $log := util:log("INFO", "$manifest-json"):)
let $log := util:log("INFO","iiif-p-test")
let $log := util:log("INFO", request:get-effective-uri())
let $log := util:log("INFO", request:get-cookie-names())

let $manifest := hra-iiif:generate-collection-manifest($collection-name, "8ceef12c-8424-4b8e-ae91-796c8d9a9738", map{}, ())

(:let $log := util:log("INFO", $manifest-json):)
return
(:    functx:atomic-type($manifest):)
(:    :)
    if($manifest instance of map()) then
        serialize($manifest, $local:json-serialize-parameters)
    else
        response:set-status-code(401)