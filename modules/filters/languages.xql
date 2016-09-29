xquery version "3.0";

import module namespace mods-common="http://exist-db.org/mods/common" at "../mods-common.xql";

declare namespace mods = "http://www.loc.gov/mods/v3";

let $cached :=  session:get-attribute("mods:cached")

let $filters := distinct-values($cached/(mods:language/mods:languageTerm))

let $processsed-filters :=
    for $filter in $filters
        let $label := mods-common:get-language-label($filter)
        let $label :=
            if ($label eq $filter)
            then ()
            else
                if ($label)
                then concat(' (', $label, ')')
                else ()
    order by upper-case($filter) ascending
    return ($filter, $label)
    
let $processsed-filters := distinct-values($processsed-filters)
let $processsed-filters :=
    <filters xmlns="">
        {
            for $processsed-filter in $processsed-filters
            return <filter>{$processsed-filter}</filter>
        }
    </filters>

return $processsed-filters
