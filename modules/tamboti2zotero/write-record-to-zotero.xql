xquery version "3.1";

import module namespace tamboti2zotero = "http://hra.uni-heidelberg.de/ns/tamboti/tamboti2zotero/" at "tamboti-to-zotero.xqm";

declare default element namespace "http://www.loc.gov/mods/v3";

let $tamboti-resources := collection(xmldb:encode('/data/commons/Buddhism Bibliography'))[position() = (1 to 10)]/mods

let $zotero-collection-key := "BWDUZNUA"

return
    for $tamboti-resource in $tamboti-resources
    
    return tamboti2zotero:write-resource($zotero-collection-key, $tamboti-resource)
