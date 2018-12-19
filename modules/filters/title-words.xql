xquery version "3.1";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $cached :=  session:get-attribute("mods:cached")

let $filters := filters:keywords($cached)
let $distinct-filters := distinct-values($filters)
let $filters-map := filters:get-frequencies($filters)

let $processed-filters :=
    array {
        for $filter in $distinct-filters
        
        return map {"frequency": $filters-map($filter), "filter": $filter, "label": $filter}
    }    
    
return $processed-filters
