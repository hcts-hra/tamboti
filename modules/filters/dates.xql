xquery version "3.0";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";

declare namespace mods = "http://www.loc.gov/mods/v3";

let $cached :=  session:get-attribute("mods:cached")

let $filters :=
        (
            $cached/mods:originInfo/mods:dateIssued,
            $cached/mods:originInfo/mods:dateCreated,
            $cached/mods:originInfo/mods:copyrightDate,
            $cached/mods:relatedItem/mods:originInfo/mods:copyrightDate,
            $cached/mods:relatedItem/mods:originInfo/mods:dateIssued,
            $cached/mods:relatedItem/mods:part/mods:date
        )
let $distinct-filters := distinct-values($filters)
let $filters-map := filters:get-frequencies($filters)

let $processsed-filters :=
    <filters xmlns="">
        {
            for $filter in $distinct-filters
            order by $filter descending
            return <filter frequency="{$filters-map($filter)}" filter="{$filter}">{normalize-space(translate($filter, '"', "'"))}</filter>
        }
    </filters>            

return $processsed-filters
