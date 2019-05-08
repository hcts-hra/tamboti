xquery version "3.1";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $cached :=  session:get-attribute("tamboti:cache")

let $mods-filters := for $author in $cached//mods:name return filters:format-name($author)
let $vra-filters := $cached//vra:agentSet//vra:name[1]/text()

let $filters := ($mods-filters, $vra-filters)
let $distinct-filters := distinct-values($filters)
let $filters-map := filters:get-frequencies($filters)

let $processsed-filters :=
    array {
        for $filter in $distinct-filters
        
        return map {"frequency": $filters-map($filter), "filter": $filter, "label": $filter}
    }     

return $processsed-filters
  