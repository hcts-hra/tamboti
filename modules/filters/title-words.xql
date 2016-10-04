xquery version "3.0";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";


let $cached :=  session:get-attribute("mods:cached")

let $filters := filters:keywords($cached)
let $distinct-filters := distinct-values($filters)
let $filters-map := filters:get-frequencies($filters)

let $processed-filters :=
    <filters xmlns="">
        {
            for $filter in $distinct-filters
            return <filter frequency="{$filters-map($filter)}" filter="{$filter}">{$filter}</filter>
        }
    </filters>
    
return $processed-filters
