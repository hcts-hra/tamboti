xquery version "3.1";

import module namespace tamboti2zotero = "http://hra.uni-heidelberg.de/ns/tamboti/tamboti2zotero/" at "tamboti-to-zotero.xqm";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace zapi="http://zotero.org/ns/api";

let $collection-name := "Buddhism Bibliography"


return ( 
(:    for $entry in httpclient:get(xs:anyURI($base-uri || "/collections" || $api-key-parameter || "&amp;format=atom"), true(), ())/httpclient:body//atom:entry:)
(:    :)
(:    return local:delete-collection($entry/zapi:key, ()):)
(:    ,:)

(:    local:create-collection($collection-name, ()):)
    
(:    tamboti2zotero:delete-item("EEHB5AC4", ()):)


    for $entry in httpclient:get(xs:anyURI($tamboti2zotero:base-uri || "/items" || $tamboti2zotero:api-key-parameter || "&amp;format=atom&amp;limit=100"), true(), ())/httpclient:body//atom:entry
    
    return tamboti2zotero:delete-item($entry/zapi:key/text(), ())
)
