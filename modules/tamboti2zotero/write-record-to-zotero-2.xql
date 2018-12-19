xquery version "3.1";

import module namespace tamboti2zotero = "http://hra.uni-heidelberg.de/ns/tamboti/tamboti2zotero/" at "tamboti-to-zotero.xqm";
import module namespace mods-to-zotero = "http://hra.uni-heidelberg.de/ns/mods-to-zotero/" at "mods-to-zotero.xqm";

declare default element namespace "http://www.loc.gov/mods/v3";

(:declare variable $local:tamboti-collection external;:)
(:declare variable $local:zotero-collection-key external;:)
let $local:tamboti-collection := xmldb:encode('/data/commons/Buddhism Bibliography')
let $local:zotero-collection-key := "BWDUZNUA"

let $counter := doc("counters.xml")//*:write-record-to-zotero
let $counter-value := number($counter)

let $tamboti-resources := collection($local:tamboti-collection)/mods
let $tamboti-resource := $tamboti-resources[position() = $counter-value]

return
(: ( :)
(:    tamboti2zotero:write-resource($local:zotero-collection-key, $tamboti-resource):)
(:    ,:)
(:    update value $counter with ($counter-value + 1):)
(: ) :)

    for $tamboti-resource at $i in $tamboti-resources
    let $tamboti-genre := if (exists($tamboti-resource/*:genre[1])) then $tamboti-resource/*:genre[1] else "book"
    let $itemType := map:get($tamboti2zotero:genre-mappings, $tamboti-genre)
    
    let $numPages := mods-to-zotero:numPages($tamboti-resource/*:physicalDescription/*:extent[@unit = 'pages'])
    
    return $numPages  
    
