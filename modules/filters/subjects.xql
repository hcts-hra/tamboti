xquery version "3.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

declare option output:method "text";
declare option output:media-type "text/plain";

let $cached :=  session:get-attribute("mods:cached")

let $all-subjects := $cached/(mods:subject | vra:work/vra:subjectSet/vra:subject/vra:term)/text()
let $subjects := distinct-values($all-subjects)

let $subjects-map :=
    map:new(
        for $value in $all-subjects
        group by $key := $value
        return map:entry($value[1], count($value)), "?strength=primary"
    )
let $processed-subjects :=
    (:No distinction is made between different kinds of subjects - topics, temporal, geographic, etc.:)
    for $subject in $subjects
    order by upper-case($subject) ascending
    (:LCSH have '--', so they have to be replaced.:)
    return $subject || " [" || $subjects-map($subject) || "]"

let $result := "[[&quot;" || string-join($processed-subjects, "&quot;], [&quot;") || "&quot;]]"    
    
return $result
