xquery version "3.0";

declare namespace mods = "http://www.loc.gov/mods/v3";

let $collection-path := "/resources/commons/"


return
    xmldb: store("/db/resources", "multilingual-collections.xml",
        <metadata>
            {(
                "Top Collection Name,Languages Other Than English&#10;"
                ,
                for $subcollection-name in xmldb:get-child-collections($collection-path)
                let $subcollection-path := $collection-path || $subcollection-name
                let $mods-records := collection($subcollection-path)/mods:mods
                let $languages := string-join(distinct-values($mods-records//@lang)[not(. = ('', 'eng'))], ' ')    
                
                return
                    if (count($languages) > 0)
                    then string-join(($subcollection-path, $languages), ', ') || "&#10;"
                    else ()
            )}
        </metadata>
    )     
