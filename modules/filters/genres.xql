xquery version "3.0";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace mods-editor = "http://hra.uni-heidelberg.de/ns/mods-editor/";

declare option output:method "text";
declare option output:media-type "text/plain";

let $cached :=  session:get-attribute("mods:cached")

let $genres := distinct-values($cached/(mods:genre))

let $processed-genres :=
    for $genre in $genres
        let $label-1 := doc(concat($config:db-path-to-mods-editor-home, '/code-tables/genre-local.xml'))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $genre]/mods-editor:label
        let $label-2 := doc(concat($config:db-path-to-mods-editor-home, '/code-tables/genre-marcgt.xml'))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $genre]/mods-editor:label
        let $label :=
            if ($label-1)
            then $label-1
            else
                if ($label-2)
                then $label-2
                else $genre
        let $label :=
            if ($label eq $genre)
            then ()
            else
                if ($label)
                then concat(' (', $label, ')')
                else ()
    order by upper-case($genre) ascending
    return ($genre, $label)

let $result := "[[&quot;" || string-join($processed-genres, "&quot;], [&quot;") || "&quot;]]"

return $result
  