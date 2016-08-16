xquery version "3.0";

import module namespace mods-common="http://exist-db.org/mods/common" at "../mods-common.xql";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mods = "http://www.loc.gov/mods/v3";

declare option output:method "text";
declare option output:media-type "text/plain";

let $cached :=  session:get-attribute("mods:cached")

let $languages := distinct-values($cached/(mods:language/mods:languageTerm))

let $processed-languages :=
    for $language in $languages
        let $label := mods-common:get-language-label($language)
        let $label :=
            if ($label eq $language)
            then ()
            else
                if ($label)
                then concat(' (', $label, ')')
                else ()
    order by upper-case($language) ascending
    return ($language, $label)

let $result := "[[&quot;" || string-join($processed-languages, "&quot;], [&quot;") || "&quot;]]"

return $result
