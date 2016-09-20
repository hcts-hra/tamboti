xquery version "3.0";

(:
 : Example: store data into mongodb
 : 
 : User must be either DBA or in group mongodb
 :)

import module namespace mongodb="http://expath.org/ns/mongo" at "java:org.exist.mongodb.xquery.MongodbModule";
import module namespace hra-iiif="http://hra.uni-heidelberg.de/ns/hra-iiif" at "/apps/tamboti/frameworks/hra-iiif/hra-iiif.xqm";

declare variable $local:json-serialize-parameters :=
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;

(:let $collection-name := xs:anyURI("/data/users/editor/Couleurkarten/Einzeln"):)
(:let $collection-name := xs:anyURI("/data/commons/Naddara/documents/1888_Chesnel_Comic_Attawadod-inlay"):)
(:let $collection-name := xs:anyURI("/data/commons/Naddara/documents"):)
(:let $collection-name := xs:anyURI("/data/commons/Naddara/Journals/1900/1_Le-Journal-d-Abou-Naddara_issues-001-005/issue_001"):)
(:let $collection-name := xs:anyURI("/data/commons/Naddara/Journals/1900/1_Le-Journal-d-Abou-Naddara_issues-001-005"):)
let $collection-name := xmldb:encode-uri("/data/users/matthias.guth@ad.uni-heidelberg.de/GrabungKMHKastellweg/Grabungstagebuch")

let $manifest-uuid := "8ceef12c-8424-4b8e-ae91-796c8d9a9738"

(:let $header := response:set-header("Content-Type", "application/json"):)

(:let $httpheader := response:set-header("access-control-allow-origin", "*"):)
let $manifest-map := hra-iiif:generate-collection-manifest($collection-name, $manifest-uuid, (), ())
(:let $manifest-json := serialize($manifest-map, $local:json-serialize-parameters):)

return
    hra-iiif:store-manifest($manifest-map)
