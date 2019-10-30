xquery version "3.1";

import module namespace config="http://exist-db.org/mods/config" at "/apps/tamboti/modules/config.xqm";
import module namespace security="http://exist-db.org/mods/security" at "/apps/tamboti/modules/search/security.xqm";
import module namespace search = "http://hra.uni-heidelberg.de/ns/tamboti/search/" at "/apps/tamboti/modules/search/search.xqm";
import module namespace retrieve = "http://hra.uni-heidelberg.de/ns/tamboti/retrieve" at "/apps/tamboti/modules/search/retrieve.xqm";

declare function local:process-form() as element(query)? {
    let $collection := xmldb:encode-uri(request:get-parameter("collection", $config:content-root))
    let $fields :=
        (:  Get a list of all input parameters which are not empty,
            ordered by input name. :)
        for $param in request:get-parameter-names()[starts-with(., 'input')]
        let $value := request:get-parameter($param, ())
        where string-length($value) gt 0
        order by $param descending
        return
            $param
            
    return
        if (exists($fields))
        then
            (:  process-form recursively calls itself for every parameter and
                generates and XML representation of the query. :)
            <query>
                <collection>{$collection}</collection>
                { search:process-form-parameters($fields) }
            </query>
        else
            <query>
                <collection>{$collection}</collection>
            </query>
};

declare function local:get-or-create-cached-results($query-as-xml as element(query)?, $sort as item()?) as xs:int {
    if ($query-as-xml//field)
    then local:execute-query($query-as-xml, $sort)
    else search:list-collection($query-as-xml, $sort)
};

declare function local:eval-query($query-as-xml as element(query)?, $sort as item()?) as xs:int {
    if ($query-as-xml) 
    then
        let $search-format := request:get-parameter("format", '')
        
        let $query := string-join(local:generate-full-query($query-as-xml), '')
        let $log := util:log("INFO", "$query as string")
        let $log := util:log("INFO", $query)
        
        (:Simple search does not have the parameter format, but should search in all formats.:)
        let $search-format := 
            if ($search-format)
            then $search-format
            else 'MODS-TEI-VRA-WIKI'
        (:If the format parameter does not contain a certain string, 
        the corresponding namepsace is stripped from the search expression, 
        leading to a search for the element in question in no namespace.:)
        let $query :=
            if (not(contains($search-format, 'MODS')))
            then replace($query, 'mods:', '')
            else $query
        let $query :=
            if (not(contains($search-format, 'VRA')))
            then replace($query, 'vra:', '')
            else $query
        let $query :=
            if (not(contains($search-format, 'TEI')))
            then replace($query, 'tei:', '')
            else $query
        let $query :=
            if (not(contains($search-format, 'Wiki') or contains($search-format, 'WIKI')))
            then replace($query, 'atom:', '')
            else $query
        let $sort := if ($sort) then $sort else session:get-attribute("sort")
        let $results := search:evaluate-query($query, $sort)
        let $processed :=
            for $item in $results
            return
                typeswitch ($item)
                    case element(results) 
                        return $item/search
                    default 
                        return $item
        (:~ Take the query results and store them into the HTTP session. :)
        let $null := session:set-attribute('mods:cached', $processed)
        let $null := session:set-attribute('query', $query-as-xml)
        let $null := session:set-attribute('sort', $query-as-xml)
        let $null := session:set-attribute('collection', $query-as-xml)
        let $null := 
            if ($query-as-xml//field)
            then search:add-to-history($query-as-xml)
            else ()        
        return
            count($processed)
    (:NB: When 0 is returned to a query, it is set here.:)
    else 0
};

declare function local:execute-query($collection as xs:string, $query-string as xs:string) {
    let $query-string :=
        if (starts-with($query-string, "*"))
        then $query-string
        else "*" || $query-string
    let $query-string :=
        if (ends-with($query-string, "*"))
        then $query-string
        else $query-string || "*"
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
        if (security:user-has-access("guest", $result/root()/document-uri(.), "r.."))
        then $result
        else ()
};

(
    session:create()
    ,
    let $collection := xmldb:encode-uri(request:get-parameter("collection", ""))
    let $query-string := request:get-parameter("q", "")
    
    let $results := local:execute-query($collection,  $query-string)
    let $filtered-results := local:filter-results($results)
    let $null := session:set-attribute("tamboti:cached", $filtered-results)
(:    let $null := session:set-attribute("tamboti:query", $query-as-xml):)
(:    let $null := session:set-attribute("tamboti:sort", $query-as-xml):)
(:    let $null := session:set-attribute("tamboti:collection", $query-as-xml)    :)
    
    return count($filtered-results)
)

(:let $collections-to-query :=:)
(:    if (ends-with($collection, $config:users-collection)):)
(:    then security:get-searcha)ble-child-collections(xs:anyURI($collection), true()):)
(:    else security:get-searchable-child-collections(xs:anyURI($collection), false()):)
(:let $sort := request:get-parameter("sort", ()):)
(::)
(:(: Process request parameters and generate an XML representation of the query :):)
(:let $query-as-xml := local:process-form():)
(:let $query-as-regex := search:get-query-as-regex($query-as-xml):)
(:let $null := session:set-attribute('regex', $query-as-regex):)
(:let $results := local:get-or-create-cached-results($query-as-xml, $sort):)
(::)
(:let $start := xs:int(request:get-parameter("start", 1)):)
(:let $count := xs:int(request:get-parameter("count", $config:number-of-items-per-page)):)
(::)
(:let $cors := response:set-header("Access-Control-Allow-Origin", "*"):)
(::)
(:let $collection-path := $query-as-xml/collection/text():)
(:    :)
(:return local:generate-full-query($query-as-xml):)

    
    
(:    retrieve:retrieve($start, $count):)



(::)
(:let $start := xs:int(request:get-parameter("start", 1)):)
(:let $count := xs:int(request:get-parameter("count", $config:number-of-items-per-page)):)
(::)
(:let $cors := response:set-header("Access-Control-Allow-Origin", "*"):)
(::)
(:return retrieve:retrieve($start, $count):)

