xquery version "3.1";

import module namespace security = "http://exist-db.org/mods/security" at "/apps/tamboti/modules/search/security.xqm";
import module namespace search = "http://hra.uni-heidelberg.de/ns/tamboti/search/" at "/apps/tamboti/modules/search/search.xqm";

declare function local:filter-results($results as element()*) {
    for $result in $results
    
    return
        if (security:user-has-access(security:get-user-credential-from-session()[1], $result/root()/document-uri(.), "r.."))
        then $result
        else ()
};

(
    session:create()
    ,
    let $collection := xmldb:encode-uri(request:get-parameter("collection", ""))
    
    let $results := collection($collection)/*
    let $filtered-results := local:filter-results($results)
    let $null := session:set-attribute("tamboti:cache", $filtered-results)
(:    let $null := session:set-attribute("tamboti:sort", $query-as-xml):)
    
    return count($filtered-results)
)
