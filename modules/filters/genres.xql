xquery version "3.0";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace mods-editor = "http://hra.uni-heidelberg.de/ns/mods-editor/";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $cached :=  session:get-attribute("mods:cached")

let $filters := $cached/(mods:genre)
let $distinct-filters := distinct-values($filters)
let $filters-map := filters:get-frequencies($filters)

let $processed-filters :=
    <filters xmlns="">
        {
            for $filter in $distinct-filters
            let $label-1 := doc(concat($config:db-path-to-mods-editor-home, '/code-tables/genre-local.xml'))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $filter]/mods-editor:label/text()
            let $label-2 := doc(concat($config:db-path-to-mods-editor-home, '/code-tables/genre-marcgt.xml'))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $filter]/mods-editor:label/text()
            let $label :=
                if ($label-1)
                then $label-1
                else
                    if ($label-2)
                    then $label-2
                    else $filter
            order by upper-case($filter) ascending
            
            return <filter frequency="{$filters-map($filter)}" filter="{$filter}" label="{$label}" />
        }
    </filters>

return $processed-filters
