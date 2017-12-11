xquery version "3.0";

declare namespace mods = "http://www.loc.gov/mods/v3";

let $collection-path := "/resources/commons/"


return
    xmldb: store("/db/resources", "multilingual-collections.xml",
        <metadata>
            {(
                "Top Collection Path,Languages Other Than English,Number Of Multilingual Records&#10;"
                ,
                for $subcollection-name in xmldb:get-child-collections($collection-path)
                let $subcollection-path := $collection-path || $subcollection-name
                let $mods-records := collection($subcollection-path)/mods:mods
                let $languages := $mods-records//@lang[not(. = ('', 'eng'))]
                let $distinct-languages := string-join(distinct-values($languages), ' ')    
                
                return
                    if (count($languages) > 0)
                    then string-join(($subcollection-path, $distinct-languages, count($languages)), ', ') || "&#10;"
                    else ()
            )}
        </metadata>
    )     
