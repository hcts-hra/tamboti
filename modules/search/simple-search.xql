xquery version "3.1";

import module namespace security = "http://exist-db.org/mods/security" at "/apps/tamboti/modules/search/security.xqm";

declare function local:execute-query($collection as xs:string, $query-string as xs:string) {
    let $query-string := string-join(tokenize($query-string, " ") ! local:process-query-string(.), " AND ")
    let $options :=
        <options>
            <default-operator>and</default-operator>
            <phrase-slop>1</phrase-slop>
            <leading-wildcard>yes</leading-wildcard>
            <filter-rewrite>yes</filter-rewrite>
        </options>
    
    let $results := collection($collection)/*[ft:query(., $query-string, $options)]
    
    return $results
};

declare function local:filter-results($results as element()*) {
    for $result in $results
    
    return
        if (security:user-has-access(security:get-user-credential-from-session()[1], $result/root()/document-uri(.), "r.."))
        then $result
        else ()
};

declare %private function local:process-query-string($query-string as xs:string) as xs:string {
    let $query-string :=
        if (starts-with($query-string, "*"))
        then $query-string
        else "*" || $query-string
    let $query-string :=
        if (ends-with($query-string, "*"))
        then $query-string
        else $query-string || "*"
        
    return $query-string
};

(
    session:create()
    ,
    let $collection := xmldb:encode-uri(request:get-parameter("collection", ""))
    let $query-string := request:get-parameter("q", "")
    
    let $results := local:execute-query($collection,  $query-string)
    let $filtered-results := local:filter-results($results)
    let $null := session:set-attribute("tamboti:cache", $filtered-results)
    let $null := session:set-attribute("tamboti:query", $query-string)
(:    let $null := session:set-attribute("tamboti:sort", $query-as-xml):)
    
    return count($filtered-results)
)
