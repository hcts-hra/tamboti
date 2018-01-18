xquery version "3.1";

import module namespace tamboti2zotero = "http://hra.uni-heidelberg.de/ns/tamboti/tamboti2zotero/" at "tamboti-to-zotero.xqm";
import module namespace crypto = "http://expath.org/ns/crypto";

let $tamboti-resources := collection(xmldb:encode('/data/commons/Buddhism Bibliography'))[position() = (1 to 15)]/mods

let $zotero-collection-key := "BWDUZNUA"

return
    for $tamboti-resource in $tamboti-resources
    let $zotero-item-key := local:write-resource($zotero-collection-key, $tamboti-resource)
    let $zotero-child-attachment-item-key := local:create-zotero-child-attachment-item($zotero-item-key, $tamboti-resource)
    
    return local:upload-tamboti-resource($tamboti-resource, $zotero-child-attachment-item-key)
