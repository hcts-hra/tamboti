xquery version "3.0";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

let $cached :=  session:get-attribute("mods:cached")

let $mods-names := for $author in $cached//mods:name return filters:format-name($author)
let $vra-names := $cached//vra:agentSet//vra:name[1]/text()

let $filters := distinct-values(($mods-names, $vra-names))
let $processsed-filters :=
    <filters xmlns="">
        {
            for $filter in $filters
            return <filter>{$filter}</filter>
        }
    </filters>

return $processsed-filters
  