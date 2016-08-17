xquery version "3.0";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";
import module namespace json="http://www.json.org";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

declare option output:method "text";
declare option output:media-type "text/plain";

let $start := util:system-time()

let $cached :=  session:get-attribute("mods:cached")

let $dates :=
    distinct-values(
        (
            $cached/mods:originInfo/mods:dateIssued,
            $cached/mods:originInfo/mods:dateCreated,
            $cached/mods:originInfo/mods:copyrightDate,
            $cached/mods:relatedItem/mods:originInfo/mods:copyrightDate,
            $cached/mods:relatedItem/mods:originInfo/mods:dateIssued,
            $cached/mods:relatedItem/mods:part/mods:date
        )
    )
let $dates-processsed :=
    for $date in $dates
    order by $date descending
    return $date

let $result := "[[&quot;" || string-join($dates-processsed, "&quot;], [&quot;") || "&quot;]]"

let $stop := util:system-time()

return $result
