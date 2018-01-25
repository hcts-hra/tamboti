xquery version "3.1";

import module namespace tamboti2zotero = "http://hra.uni-heidelberg.de/ns/tamboti/tamboti2zotero/" at "tamboti-to-zotero.xqm";

declare default element namespace "http://www.loc.gov/mods/v3";

declare variable $local:tamboti-collection external;
declare variable $local:zotero-collection-key external;
(:let $login := xmldb:login("/db"):)

let $counter := doc("counters.xml")//*:write-record-to-zotero
let $counter-value := number($counter)
let $tamboti-resource := collection($local:tamboti-collection)[position() = $counter-value]/mods

return (
    tamboti2zotero:write-resource($local:zotero-collection-key, $tamboti-resource)
    ,
    update value $counter with ($counter-value + 1)
)
(:    for $tamboti-resource in $tamboti-resources:)
(:    :)
(:    return tamboti2zotero:write-resource($zotero-collection-key, $tamboti-resource):)
