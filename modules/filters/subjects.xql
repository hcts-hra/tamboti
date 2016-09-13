xquery version "3.0";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

declare option output:method "text";
declare option output:media-type "text/plain";

let $cached :=  session:get-attribute("mods:cached")

let $filters := $cached/(mods:subject | vra:work/vra:subjectSet/vra:subject/vra:term)/text()
let $distinct-filters := distinct-values($filters)

let $filters-map := filters:get-frequencies($filters)
    
let $processed-filters :=
    (:No distinction is made between different kinds of subjects - topics, temporal, geographic, etc.:)
    for $filter in $distinct-filters
    order by upper-case($filter) ascending
    (:LCSH have '--', so they have to be replaced.:)
    return $filter || " [" || $filters-map($filter) || "]"

let $result := "[[&quot;" || string-join($processed-filters, "&quot;], [&quot;") || "&quot;]]"    
    
return $result
