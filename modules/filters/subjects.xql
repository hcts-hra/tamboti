xquery version "3.1";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $cached :=  session:get-attribute("tamboti:cache")

let $filters := $cached/(mods:subject | vra:work/vra:subjectSet/vra:subject/vra:term)/text()
let $distinct-filters := distinct-values($filters)
let $filters-map := filters:get-frequencies($filters)
    
let $processed-filters :=
    array {
        (:No distinction is made between different kinds of subjects - topics, temporal, geographic, etc.:)
        for $filter in $distinct-filters
        order by upper-case($filter) ascending
        
        return map {"frequency": $filters-map($filter), "filter": $filter, "label": $filter}
    }    
    
return $processed-filters
