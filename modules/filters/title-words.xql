xquery version "3.0";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";


let $cached :=  session:get-attribute("mods:cached")

let $filters := filters:keywords($cached)

let $processed-filters :=
    <filters xmlns="">
        {
            for $filter in $filters
            return <filter>{$filters}</filter>
        }
    </filters>
    
return $processed-filters
