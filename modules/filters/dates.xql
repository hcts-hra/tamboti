xquery version "3.0";


declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mods = "http://www.loc.gov/mods/v3";

let $cached :=  session:get-attribute("mods:cached")

let $filters :=
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
let $processsed-filters :=
    <filters xmlns="">
        {
            for $filter in $filters
            order by $filter descending
            return <filter>{normalize-space(translate($filter, '"', "'"))}</filter>
        }
    </filters>            

return $processsed-filters
  