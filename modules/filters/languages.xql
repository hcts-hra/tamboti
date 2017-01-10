xquery version "3.0";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";
import module namespace mods-common="http://exist-db.org/mods/common" at "../mods-common.xql";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $cached :=  session:get-attribute("mods:cached")

let $filters := $cached/(mods:language/mods:languageTerm)
let $distinct-filters := distinct-values($filters)
let $filters-map := filters:get-frequencies($filters)

let $processsed-filters :=
    <filters xmlns="">
        {
            for $filter in $distinct-filters
                let $label := mods-common:get-language-label($filter)
                order by upper-case($filter) ascending
            return <filter frequency="{$filters-map($filter)}" filter="{$filter}">{$label}</filter>
        }
    </filters>            


return $processsed-filters
