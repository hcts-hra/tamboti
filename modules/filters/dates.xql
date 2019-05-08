xquery version "3.1";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $cached :=  session:get-attribute("tamboti:cache")

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
    array {
        for $filter in $distinct-filters
        let $normalized-filter := normalize-space($filter)
        order by $filter descending
        
        return map {"frequency": $filters-map($filter), "filter": $normalized-filter, "label": translate($normalized-filter, '"', "'")}
    }    

return $processsed-filters
